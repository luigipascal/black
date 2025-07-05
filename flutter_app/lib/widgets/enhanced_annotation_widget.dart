import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enhanced_document_models.dart';
import '../constants/app_theme.dart';
import '../providers/enhanced_revelation_provider.dart';

class EnhancedAnnotationWidget extends StatefulWidget {
  final EnhancedAnnotation annotation;
  final Size pageSize;
  final EdgeInsets margins;
  final VoidCallback? onTap;

  const EnhancedAnnotationWidget({
    super.key,
    required this.annotation,
    required this.pageSize,
    required this.margins,
    this.onTap,
  });

  @override
  State<EnhancedAnnotationWidget> createState() => _EnhancedAnnotationWidgetState();
}

class _EnhancedAnnotationWidgetState extends State<EnhancedAnnotationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bobAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    ));

    // Subtle bob animation for post-it notes
    _bobAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Start animation with slight delay based on annotation ID
    final delay = (widget.annotation.id.hashCode % 500).abs();
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) {
        _animationController.forward();
        // For post-it notes, start gentle bobbing
        if (widget.annotation.isDraggable) {
          _startBobbing();
        }
      }
    });
  }

  void _startBobbing() {
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedRevelationProvider>(
      builder: (context, revelationProvider, child) {
        if (!revelationProvider.isAnnotationVisible(widget.annotation)) {
          return const SizedBox.shrink();
        }

        final character = revelationProvider.characters[widget.annotation.character];
        if (character == null) return const SizedBox.shrink();

        // Get custom position if annotation was dragged
        final customPosition = revelationProvider.userProgress
            .customAnnotationPositions[widget.annotation.id];
        final position = customPosition ?? widget.annotation.position;

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final double left = position.x * widget.pageSize.width;
            final double top = position.y * widget.pageSize.height;

            return Positioned(
              left: left,
              top: top + (widget.annotation.isDraggable ? _bobAnimation.value : 0),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.rotate(
                    angle: position.rotation,
                    child: _buildAnnotationContent(character, revelationProvider),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnnotationContent(EnhancedCharacter character, EnhancedRevelationProvider revelationProvider) {
    final isPostIt = widget.annotation.isDraggable;
    final annotationStyle = character.annotationStyle;

    Widget content = Container(
      constraints: const BoxConstraints(maxWidth: 200, maxHeight: 150),
      padding: isPostIt ? const EdgeInsets.all(12) : const EdgeInsets.all(4),
      decoration: _getAnnotationDecoration(isPostIt, annotationStyle),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Character indicator (small)
          if (isPostIt)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: _parseColor(annotationStyle.color).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                character.name,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: _parseColor(annotationStyle.color),
                ),
              ),
            ),
          
          if (isPostIt) const SizedBox(height: 4),
          
          // Annotation text
          Flexible(
            child: Text(
              widget.annotation.text,
              style: _getCharacterTextStyle(annotationStyle),
              maxLines: isPostIt ? 8 : 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Year indicator for historical context
          if (widget.annotation.year != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${widget.annotation.year}',
                style: TextStyle(
                  fontSize: 8,
                  color: _parseColor(annotationStyle.color).withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );

    // Make post-it notes draggable
    if (isPostIt) {
      content = Draggable<EnhancedAnnotation>(
        data: widget.annotation,
        feedback: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 200),
            padding: const EdgeInsets.all(12),
            decoration: _getAnnotationDecoration(true, annotationStyle),
            child: Text(
              widget.annotation.text,
              style: _getCharacterTextStyle(annotationStyle),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: content,
        ),
        onDragEnd: (details) {
          _handleDragEnd(details, revelationProvider);
        },
        child: content,
      );
    }

    return GestureDetector(
      onTap: () {
        widget.onTap?.call();
        _showAnnotationDetail(character, revelationProvider);
      },
      child: content,
    );
  }

  BoxDecoration _getAnnotationDecoration(bool isPostIt, AnnotationStyle style) {
    if (isPostIt) {
      return BoxDecoration(
        color: _getPostItColor(widget.annotation.character),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _parseColor(style.color).withOpacity(0.3),
          width: 1,
        ),
      );
    } else {
      // Fixed marginalia - subtle background
      return BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(2),
      );
    }
  }

  Color _getPostItColor(String character) {
    switch (character) {
      case 'SW':
        return const Color(0xFFFFF68F); // Yellow
      case 'Detective Sharma':
        return const Color(0xFFE6FFE6); // Light green
      case 'Dr. Chambers':
        return const Color(0xFFFFE6E6); // Light red
      default:
        return const Color(0xFFFFF68F); // Default yellow
    }
  }

  TextStyle _getCharacterTextStyle(AnnotationStyle style) {
    return TextStyle(
      fontFamily: _getFontFamily(style.fontFamily),
      fontSize: style.fontSize.toDouble(),
      color: _parseColor(style.color),
      fontStyle: style.fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
      fontWeight: style.fontStyle == 'bold' ? FontWeight.bold : FontWeight.normal,
    );
  }

  String _getFontFamily(String fontFamily) {
    switch (fontFamily.toLowerCase()) {
      case 'dancing script':
        return 'Cursive';
      case 'courier new':
      case 'courier prime':
        return 'Courier';
      case 'kalam':
        return 'Sans-serif';
      case 'architects daughter':
        return 'Sans-serif';
      default:
        return 'Serif';
    }
  }

  Color _parseColor(String colorString) {
    if (colorString.startsWith('#')) {
      return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
    }
    return AppTheme.marginaliaBlack;
  }

  void _handleDragEnd(DraggableDetails details, EnhancedRevelationProvider revelationProvider) {
    // Update annotation position
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final localPosition = renderBox.globalToLocal(details.offset);
      final newPosition = AnnotationPosition(
        zone: widget.annotation.position.zone,
        x: (localPosition.dx / widget.pageSize.width).clamp(0.0, 1.0),
        y: (localPosition.dy / widget.pageSize.height).clamp(0.0, 1.0),
        rotation: widget.annotation.position.rotation,
      );
      
      revelationProvider.updateAnnotationPosition(widget.annotation.id, newPosition);
    }
  }

  void _showAnnotationDetail(EnhancedCharacter character, EnhancedRevelationProvider revelationProvider) {
    showDialog(
      context: context,
      builder: (context) => _buildAnnotationDetailDialog(character, revelationProvider),
    );
  }

  Widget _buildAnnotationDetailDialog(EnhancedCharacter character, EnhancedRevelationProvider revelationProvider) {
    final isDiscovered = revelationProvider.discoveredCharacters.contains(widget.annotation.character);
    
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
                    color: _parseColor(character.annotationStyle.color),
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
                if (isDiscovered)
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
                border: Border.all(
                  color: _parseColor(character.annotationStyle.color).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.annotation.year != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _parseColor(character.annotationStyle.color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.annotation.year}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _parseColor(character.annotationStyle.color),
                        ),
                      ),
                    ),
                  
                  if (widget.annotation.year != null) const SizedBox(height: 8),
                  
                  Text(
                    widget.annotation.text,
                    style: _getCharacterTextStyle(character.annotationStyle),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Character information
            if (isDiscovered) ...[
              Text(
                'Character Information',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(character.description),
              
              const SizedBox(height: 12),
              
              // Mystery role
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mystery Role',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(character.mysteryRole),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Key themes
              if (character.keyThemes.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: character.keyThemes.map((theme) => Chip(
                    label: Text(theme, style: const TextStyle(fontSize: 12)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: _parseColor(character.annotationStyle.color).withOpacity(0.1),
                  )).toList(),
                ),
            ] else ...[
              // Discovery prompt
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.help_outline, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Find more annotations from this character to unlock their story...',
                        style: TextStyle(color: Colors.amber[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Revelation info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getRevelationLevelColor(widget.annotation.revealLevel).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revelation Level: ${widget.annotation.revealLevel.level}/5',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Required: ${widget.annotation.revealLevel.name}',
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
                  backgroundColor: _parseColor(character.annotationStyle.color),
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
}