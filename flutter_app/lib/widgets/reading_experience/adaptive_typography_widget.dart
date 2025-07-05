import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/reading_experience_service.dart';
import '../../models/enhanced_document_models.dart';

class AdaptiveTypographyWidget extends StatefulWidget {
  final String content;
  final int pageNumber;
  final List<EnhancedAnnotation> annotations;
  final VoidCallback? onReadingStarted;
  final VoidCallback? onReadingEnded;

  const AdaptiveTypographyWidget({
    super.key,
    required this.content,
    required this.pageNumber,
    this.annotations = const [],
    this.onReadingStarted,
    this.onReadingEnded,
  });

  @override
  State<AdaptiveTypographyWidget> createState() => _AdaptiveTypographyWidgetState();
}

class _AdaptiveTypographyWidgetState extends State<AdaptiveTypographyWidget>
    with WidgetsBindingObserver {
  final ReadingExperienceService _readingService = ReadingExperienceService();
  
  bool _isReading = false;
  DateTime? _readingStartTime;
  ScrollController? _scrollController;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController = ScrollController();
    
    // Start reading session when widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startReadingSession();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _endReadingSession();
    _scrollController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _endReadingSession();
        break;
      case AppLifecycleState.resumed:
        _startReadingSession();
        break;
      default:
        break;
    }
  }

  void _startReadingSession() {
    if (!_isReading) {
      _isReading = true;
      _readingStartTime = DateTime.now();
      _readingService.startReadingSession(widget.pageNumber);
      widget.onReadingStarted?.call();
    }
  }

  void _endReadingSession() {
    if (_isReading) {
      _isReading = false;
      final wordsRead = _countWords(widget.content);
      _readingService.endReadingSession(widget.pageNumber, wordsRead: wordsRead);
      widget.onReadingEnded?.call();
    }
  }

  int _countWords(String text) {
    return text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  @override
  Widget build(BuildContext context) {
    final typography = _readingService.getTypographyForPage(widget.pageNumber);
    final readingMode = _readingService.getReadingModeConfig();
    
    return Container(
      color: readingMode.backgroundColor,
      child: Padding(
        padding: EdgeInsets.all(16.0 * readingMode.marginMultiplier),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reading time estimation
              _buildReadingTimeEstimate(typography),
              
              const SizedBox(height: 24),
              
              // Main content with adaptive typography
              _buildAdaptiveContent(typography, readingMode),
              
              const SizedBox(height: 32),
              
              // Page annotations
              if (widget.annotations.isNotEmpty)
                _buildAnnotationsSection(typography, readingMode),
              
              // Reading progress indicator
              const SizedBox(height: 24),
              _buildReadingProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadingTimeEstimate(TypographyConfig typography) {
    final estimatedTime = _readingService.estimateReadingTime(
      widget.pageNumber, 
      widget.content,
    );
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            size: 16,
            color: Colors.blue[600],
          ),
          const SizedBox(width: 6),
          Text(
            'Est. ${estimatedTime.inMinutes}m ${estimatedTime.inSeconds % 60}s',
            style: TextStyle(
              fontSize: typography.baseFontSize * 0.75,
              color: Colors.blue[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_countWords(widget.content)} words',
            style: TextStyle(
              fontSize: typography.baseFontSize * 0.7,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptiveContent(TypographyConfig typography, ReadingModeConfig readingMode) {
    final textStyle = TextStyle(
      fontSize: typography.baseFontSize,
      height: typography.lineHeight,
      letterSpacing: typography.letterSpacing,
      fontWeight: typography.fontWeight,
      fontFamily: typography.fontFamily,
      color: _adjustColorForReadingMode(typography.color, readingMode),
    );

    // Parse content into paragraphs
    final paragraphs = widget.content.split('\n\n').where((p) => p.trim().isNotEmpty);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((paragraph) {
        // Detect different content types for adaptive styling
        if (paragraph.startsWith('#')) {
          return _buildHeading(paragraph, typography, readingMode);
        } else if (paragraph.startsWith('> ')) {
          return _buildBlockQuote(paragraph, typography, readingMode);
        } else if (paragraph.contains('███')) {
          return _buildRedactedText(paragraph, typography, readingMode);
        } else {
          return _buildParagraph(paragraph, textStyle, typography);
        }
      }).toList(),
    );
  }

  Widget _buildHeading(String heading, TypographyConfig typography, ReadingModeConfig readingMode) {
    final level = heading.split('#').length - 1;
    final text = heading.replaceAll(RegExp(r'^#+\s*'), '');
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: typography.paragraphSpacing * 0.75,
        top: typography.paragraphSpacing * 1.5,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: typography.baseFontSize * (2.0 - (level * 0.2)),
          fontWeight: FontWeight.bold,
          color: _adjustColorForReadingMode(typography.color, readingMode),
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildBlockQuote(String quote, TypographyConfig typography, ReadingModeConfig readingMode) {
    final text = quote.replaceAll(RegExp(r'^>\s*'), '');
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: typography.paragraphSpacing),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderLeft: BorderSide(
          color: Colors.grey[400]!,
          width: 4,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: typography.baseFontSize * 0.95,
          fontStyle: FontStyle.italic,
          color: _adjustColorForReadingMode(Colors.grey[700]!, readingMode),
          height: typography.lineHeight,
        ),
      ),
    );
  }

  Widget _buildRedactedText(String text, TypographyConfig typography, ReadingModeConfig readingMode) {
    // Split text around redacted parts
    final parts = text.split(RegExp(r'(███+)'));
    
    return Padding(
      padding: EdgeInsets.only(bottom: typography.paragraphSpacing),
      child: RichText(
        text: TextSpan(
          children: parts.map((part) {
            if (part.startsWith('███')) {
              return WidgetSpan(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    '█' * (part.length ~/ 3),
                    style: TextStyle(
                      fontSize: typography.baseFontSize,
                      color: Colors.black,
                    ),
                  ),
                ),
              );
            } else {
              return TextSpan(
                text: part,
                style: TextStyle(
                  fontSize: typography.baseFontSize,
                  height: typography.lineHeight,
                  letterSpacing: typography.letterSpacing,
                  fontWeight: typography.fontWeight,
                  fontFamily: typography.fontFamily,
                  color: _adjustColorForReadingMode(typography.color, readingMode),
                ),
              );
            }
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildParagraph(String paragraph, TextStyle textStyle, TypographyConfig typography) {
    return Padding(
      padding: EdgeInsets.only(bottom: typography.paragraphSpacing),
      child: Text(
        paragraph,
        style: textStyle,
        textAlign: TextAlign.justify,
      ),
    );
  }

  Widget _buildAnnotationsSection(TypographyConfig typography, ReadingModeConfig readingMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: Colors.grey[300]),
        const SizedBox(height: 16),
        
        Text(
          'Annotations',
          style: TextStyle(
            fontSize: typography.baseFontSize * 1.2,
            fontWeight: FontWeight.bold,
            color: _adjustColorForReadingMode(typography.color, readingMode),
          ),
        ),
        
        const SizedBox(height: 12),
        
        ...widget.annotations.map((annotation) => _buildAnnotationItem(annotation, typography, readingMode)),
      ],
    );
  }

  Widget _buildAnnotationItem(EnhancedAnnotation annotation, TypographyConfig typography, ReadingModeConfig readingMode) {
    final character = _getCharacterColor(annotation.character);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: character.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: character.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 8,
                backgroundColor: character,
                child: Text(
                  annotation.character.substring(0, 1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                annotation.character,
                style: TextStyle(
                  fontSize: typography.baseFontSize * 0.85,
                  fontWeight: FontWeight.bold,
                  color: character,
                ),
              ),
              const Spacer(),
              if (annotation.year != null)
                Text(
                  annotation.year.toString(),
                  style: TextStyle(
                    fontSize: typography.baseFontSize * 0.75,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            annotation.text,
            style: TextStyle(
              fontSize: typography.baseFontSize * 0.9,
              height: typography.lineHeight * 0.9,
              color: _adjustColorForReadingMode(typography.color, readingMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingProgressIndicator() {
    return StreamBuilder<ReadingProgress>(
      stream: Stream.periodic(const Duration(seconds: 1)).map((_) =>
          _readingService.getReadingProgress(widget.pageNumber)),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        
        final progress = snapshot.data!;
        final currentTime = _isReading && _readingStartTime != null
            ? DateTime.now().difference(_readingStartTime!)
            : progress.actualTime;
        
        final progressPercent = progress.estimatedTime.inSeconds > 0
            ? (currentTime.inSeconds / progress.estimatedTime.inSeconds).clamp(0.0, 1.0)
            : 0.0;
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reading Progress',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    '${(progressPercent * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[600],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              LinearProgressIndicator(
                value: progressPercent,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(Colors.blue[400]!),
                minHeight: 4,
              ),
              
              const SizedBox(height: 8),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${currentTime.inMinutes}:${(currentTime.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${progress.estimatedTime.inMinutes}:${(progress.estimatedTime.inSeconds % 60).toString().padLeft(2, '0')} est.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _adjustColorForReadingMode(Color baseColor, ReadingModeConfig readingMode) {
    if (readingMode.backgroundColor == Colors.white) {
      return baseColor;
    }
    
    // Adjust color for dark/night modes
    if (readingMode.backgroundColor.computeLuminance() < 0.5) {
      return readingMode.textColor;
    }
    
    return baseColor;
  }

  Color _getCharacterColor(String character) {
    switch (character) {
      case 'MB':
        return Colors.blue;
      case 'JR':
        return Colors.orange;
      case 'EW':
        return Colors.red;
      case 'SW':
        return Colors.green;
      case 'Detective Sharma':
        return Colors.purple;
      case 'Dr. Chambers':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}