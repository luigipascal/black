import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enhanced_document_models.dart';
import '../providers/enhanced_revelation_provider.dart';
import '../constants/app_colors.dart';
import '../constants/character_fonts.dart';

class EnhancedDocumentPageWidget extends StatefulWidget {
  final DocumentPage page;
  final bool isInteractive;

  const EnhancedDocumentPageWidget({
    Key? key,
    required this.page,
    this.isInteractive = true,
  }) : super(key: key);

  @override
  State<EnhancedDocumentPageWidget> createState() => _EnhancedDocumentPageWidgetState();
}

class _EnhancedDocumentPageWidgetState extends State<EnhancedDocumentPageWidget>
    with TickerProviderStateMixin {
  late AnimationController _annotationController;
  late AnimationController _revelationController;
  final Map<String, AnimationController> _annotationAnimations = {};
  final Map<String, bool> _revealedRedactions = {};

  @override
  void initState() {
    super.initState();
    _annotationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _revelationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Start annotation appearance animation
    _annotationController.forward();
  }

  @override
  void dispose() {
    _annotationController.dispose();
    _revelationController.dispose();
    for (final controller in _annotationAnimations.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedRevelationProvider>(
      builder: (context, revelationProvider, child) {
        final visibleAnnotations = revelationProvider.getVisibleAnnotationsForPage(widget.page.pageNumber);
        
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.paperColor, AppColors.paperDark],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Paper texture overlay
              _buildPaperTexture(),
              
              // Main content
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chapter title with revelation level indicator
                      _buildChapterHeader(revelationProvider),
                      
                      const SizedBox(height: 16),
                      
                      // Page content with redacted text handling
                      Expanded(
                        child: SingleChildScrollView(
                          child: _buildPageContent(revelationProvider),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Annotations overlay
              ...visibleAnnotations.map((annotation) => 
                _buildAnnotation(annotation, revelationProvider)),
              
              // Revelation level change animation overlay
              if (_revelationController.isAnimating)
                _buildRevelationChangeOverlay(revelationProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaperTexture() {
    return Positioned.fill(
      child: CustomPaint(
        painter: PaperTexturePainter(),
      ),
    );
  }

  Widget _buildChapterHeader(EnhancedRevelationProvider provider) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.textColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _formatChapterName(widget.page.chapterName),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
          ),
          // Revelation level indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFF4ECDC4)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Level ${provider.currentRevelationLevel.level}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(EnhancedRevelationProvider provider) {
    return _buildRichTextWithRedactions(
      widget.page.content,
      provider,
    );
  }

  Widget _buildRichTextWithRedactions(String content, EnhancedRevelationProvider provider) {
    final spans = <TextSpan>[];
    final redactionPattern = RegExp(r'\[REDACTED\]|\[CLASSIFIED\]|\[DATA EXPUNGED\]|\[REMOVED BY ORDER OF\]');
    
    int lastIndex = 0;
    final matches = redactionPattern.allMatches(content);
    
    for (final match in matches) {
      // Add text before redaction
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: content.substring(lastIndex, match.start),
          style: _getContentTextStyle(),
        ));
      }
      
      // Add redacted content
      final redactionId = 'redaction_${match.start}';
      final isRevealed = _revealedRedactions[redactionId] ?? false;
      final canReveal = provider.currentRevelationLevel == RevealLevel.completeTruth;
      
      spans.add(TextSpan(
        text: isRevealed ? _getRevealedText(match.group(0)!) : match.group(0)!,
        style: _getRedactionTextStyle(isRevealed, canReveal),
        recognizer: canReveal && widget.isInteractive
          ? (TapGestureRecognizer()
              ..onTap = () => _revealRedaction(redactionId, provider))
          : null,
      ));
      
      lastIndex = match.end;
    }
    
    // Add remaining text
    if (lastIndex < content.length) {
      spans.add(TextSpan(
        text: content.substring(lastIndex),
        style: _getContentTextStyle(),
      ));
    }
    
    return RichText(
      text: TextSpan(children: spans),
      textAlign: TextAlign.justify,
    );
  }

  Widget _buildAnnotation(EnhancedAnnotation annotation, EnhancedRevelationProvider provider) {
    final character = provider.characters[annotation.character];
    if (character == null) return const SizedBox.shrink();

    // Get custom position if dragged
    final customPosition = provider.userProgress.customAnnotationPositions[annotation.id];
    final position = customPosition ?? annotation.position;

    // Create animation controller for this annotation if not exists
    if (!_annotationAnimations.containsKey(annotation.id)) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 500 + (annotation.id.hashCode % 1000)),
        vsync: this,
      );
      _annotationAnimations[annotation.id] = controller;
      
      // Stagger animation start
      Future.delayed(Duration(milliseconds: annotation.id.hashCode % 1000), () {
        if (mounted) controller.forward();
      });
    }

    final animationController = _annotationAnimations[annotation.id]!;
    
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final scaleAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animationController,
          curve: Curves.elasticOut,
        ));

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animationController,
          curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
        ));

        return Positioned(
          left: position.x * MediaQuery.of(context).size.width,
          top: position.y * MediaQuery.of(context).size.height,
          child: Transform.scale(
            scale: scaleAnimation.value,
            child: Opacity(
              opacity: fadeAnimation.value,
              child: Transform.rotate(
                angle: position.rotation,
                child: _buildAnnotationWidget(annotation, character, provider),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnnotationWidget(EnhancedAnnotation annotation, EnhancedCharacter character, EnhancedRevelationProvider provider) {
    final isPostIt = annotation.type == AnnotationType.postIt || annotation.isPost2000;
    
    Widget annotationContent = Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: isPostIt ? const EdgeInsets.all(8) : EdgeInsets.zero,
      decoration: isPostIt ? BoxDecoration(
        color: const Color(0xFFFFF68F),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ) : null,
      child: Text(
        annotation.text,
        style: _getCharacterTextStyle(character),
      ),
    );

    // Make post-it notes draggable
    if (isPostIt && widget.isInteractive) {
      annotationContent = Draggable<EnhancedAnnotation>(
        data: annotation,
        feedback: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 180),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF68F),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              annotation.text,
              style: _getCharacterTextStyle(character),
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: annotationContent,
        ),
        onDragEnd: (details) {
          // Update annotation position
          final renderBox = context.findRenderObject() as RenderBox;
          final localPosition = renderBox.globalToLocal(details.offset);
          final newPosition = AnnotationPosition(
            zone: annotation.position.zone,
            x: localPosition.dx / renderBox.size.width,
            y: localPosition.dy / renderBox.size.height,
            rotation: annotation.position.rotation,
          );
          
          provider.updateAnnotationPosition(annotation.id, newPosition);
        },
        child: annotationContent,
      );
    }

    return GestureDetector(
      onTap: widget.isInteractive ? () => _showAnnotationDetail(annotation, character, provider) : null,
      child: annotationContent,
    );
  }

  Widget _buildRevelationChangeOverlay(EnhancedRevelationProvider provider) {
    return AnimatedBuilder(
      animation: _revelationController,
      builder: (context, child) {
        final fadeAnimation = Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(CurvedAnimation(
          parent: _revelationController,
          curve: Curves.easeOut,
        ));

        return Positioned.fill(
          child: Opacity(
            opacity: fadeAnimation.value,
            child: Container(
              color: const Color(0xFFFFEB3B).withOpacity(0.3),
              child: const Center(
                child: Text(
                  '🔓 New Content Revealed!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Event handlers
  void _revealRedaction(String redactionId, EnhancedRevelationProvider provider) {
    setState(() {
      _revealedRedactions[redactionId] = true;
    });
    
    provider.revealRedaction(redactionId);
    
    // Show revelation animation
    _revelationController.forward().then((_) {
      _revelationController.reset();
    });
  }

  void _showAnnotationDetail(EnhancedAnnotation annotation, EnhancedCharacter character, EnhancedRevelationProvider provider) {
    // Trigger character discovery
    provider.discoverCharacter(annotation.character);
    provider.unlockAnnotation(annotation.id);

    showDialog(
      context: context,
      builder: (context) => _buildAnnotationDetailDialog(annotation, character, provider),
    );
  }

  Widget _buildAnnotationDetailDialog(EnhancedAnnotation annotation, EnhancedCharacter character, EnhancedRevelationProvider provider) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Character header
            Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getCharacterColor(character),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        character.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${character.role} • ${character.years}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Discovery badge
                if (provider.discoveredCharacters.contains(annotation.character))
                  const Icon(Icons.check_circle, color: Colors.green, size: 24),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Annotation content
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getCharacterColor(character).withOpacity(0.3)),
              ),
              child: Text(
                annotation.text,
                style: _getCharacterTextStyle(character),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Character info
            Text(
              'Character Information',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(character.description),
            
            const SizedBox(height: 16),
            
            // Mystery role and themes
            Wrap(
              spacing: 8,
              children: [
                ...character.keyThemes.map((theme) => Chip(
                  label: Text(theme, style: const TextStyle(fontSize: 12)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Revelation info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEB3B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revelation Level: ${annotation.revealLevel.level}/5',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Required: ${annotation.revealLevel.name}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Close button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getCharacterColor(character),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Style helpers
  TextStyle _getContentTextStyle() {
    return const TextStyle(
      fontSize: 14,
      height: 1.6,
      color: AppColors.textColor,
      fontFamily: 'Georgia',
    );
  }

  TextStyle _getRedactionTextStyle(bool isRevealed, bool canReveal) {
    if (isRevealed) {
      return _getContentTextStyle().copyWith(
        backgroundColor: const Color(0xFFFFEB3B),
        color: AppColors.textColor,
      );
    } else {
      return _getContentTextStyle().copyWith(
        backgroundColor: const Color(0xFF2C2C2C),
        color: const Color(0xFF2C2C2C),
        decoration: canReveal ? TextDecoration.underline : null,
      );
    }
  }

  TextStyle _getCharacterTextStyle(EnhancedCharacter character) {
    return TextStyle(
      fontFamily: _getFontFamily(character.annotationStyle.fontFamily),
      fontSize: character.annotationStyle.fontSize.toDouble(),
      color: _parseColor(character.annotationStyle.color),
      fontStyle: character.annotationStyle.fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
    );
  }

  Color _getCharacterColor(EnhancedCharacter character) {
    return _parseColor(character.annotationStyle.color);
  }

  String _getFontFamily(String fontFamily) {
    switch (fontFamily.toLowerCase()) {
      case 'dancing script':
        return CharacterFonts.elegant;
      case 'courier new':
      case 'courier prime':
        return CharacterFonts.typewriter;
      case 'arial':
      case 'architects daughter':
        return CharacterFonts.technical;
      default:
        return CharacterFonts.handwritten;
    }
  }

  Color _parseColor(String colorString) {
    if (colorString.startsWith('#')) {
      return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
    }
    return AppColors.textColor;
  }

  String _formatChapterName(String chapterName) {
    return chapterName
        .replaceAll('_', ' ')
        .replaceAllMapped(RegExp(r'CHAPTER (\w+)'), (match) => 'Chapter ${match.group(1)}:');
  }

  String _getRevealedText(String redactedText) {
    const revealMap = {
      '[REDACTED]': 'dimensional entities',
      '[CLASSIFIED]': 'supernatural manifestations',
      '[DATA EXPUNGED]': 'The Watchers',
      '[REMOVED BY ORDER OF]': 'Department 8 - Anomalous Phenomena Division',
    };
    return revealMap[redactedText] ?? 'classified information';
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