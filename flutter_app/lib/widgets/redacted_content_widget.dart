import 'package:flutter/material.dart';
import '../models/enhanced_document_models.dart';
import '../constants/app_theme.dart';

class RedactedContentWidget extends StatefulWidget {
  final RedactedContent redactedContent;
  final bool isRevealed;
  final VoidCallback? onReveal;

  const RedactedContentWidget({
    super.key,
    required this.redactedContent,
    required this.isRevealed,
    this.onReveal,
  });

  @override
  State<RedactedContentWidget> createState() => _RedactedContentWidgetState();
}

class _RedactedContentWidgetState extends State<RedactedContentWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _flashAnimation;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _flashAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isRevealed ? null : _handleReveal,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: _getRedactionDecoration(),
                child: _buildContent(context),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (widget.isRevealed) {
      return _buildRevealedContent(context);
    } else {
      return _buildRedactedContent(context);
    }
  }

  Widget _buildRedactedContent(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Redacted bars
        _buildRedactedBars(),
        
        // Classification label
        const SizedBox(width: 4),
        Text(
          widget.redactedContent.classification,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: _getClassificationColor(),
            letterSpacing: 0.5,
          ),
        ),
        
        // Tap hint
        if (_isHovered && widget.onReveal != null) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.touch_app,
            size: 12,
            color: Colors.red.withOpacity(0.7),
          ),
        ],
      ],
    );
  }

  Widget _buildRedactedBars() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        _getRedactionLength(),
        (index) => Container(
          width: 8,
          height: 12,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: _getRedactionColor(),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }

  Widget _buildRevealedContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.yellow.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.orange, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Unlock icon
          Icon(
            Icons.lock_open,
            size: 12,
            color: Colors.orange[700],
          ),
          const SizedBox(width: 4),
          
          // Revealed text
          Text(
            widget.redactedContent.revealedText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.orange[900],
              backgroundColor: Colors.yellow.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _getRedactionDecoration() {
    if (widget.isRevealed) {
      return BoxDecoration(
        color: Colors.yellow.withOpacity(0.1 + (_flashAnimation.value * 0.2)),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.orange.withOpacity(0.5 + (_flashAnimation.value * 0.5)),
          width: 1,
        ),
      );
    } else {
      return BoxDecoration(
        color: _getRedactionColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _getRedactionColor().withOpacity(_isHovered ? 0.7 : 0.3),
          width: 1,
        ),
      );
    }
  }

  Color _getRedactionColor() {
    switch (widget.redactedContent.classification) {
      case 'CLASSIFIED':
        return Colors.red;
      case 'TOP SECRET':
        return Colors.deepPurple;
      case 'CONFIDENTIAL':
        return Colors.orange;
      case 'RESTRICTED':
        return Colors.amber;
      default:
        return Colors.grey[800] ?? Colors.grey;
    }
  }

  Color _getClassificationColor() {
    return _getRedactionColor();
  }

  int _getRedactionLength() {
    // Determine redaction bar length based on text length
    final textLength = widget.redactedContent.hiddenText.length;
    if (textLength < 10) return 3;
    if (textLength < 20) return 5;
    if (textLength < 40) return 8;
    return 12;
  }

  void _handleReveal() {
    if (widget.onReveal != null) {
      widget.onReveal!();
      
      // Start flash animation
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
  }
}

// Widget for multiple redacted sections in a paragraph
class RedactedParagraphWidget extends StatelessWidget {
  final String content;
  final List<RedactedContent> redactedSections;
  final bool Function(RedactedContent) isRevealed;
  final void Function(RedactedContent) onReveal;

  const RedactedParagraphWidget({
    super.key,
    required this.content,
    required this.redactedSections,
    required this.isRevealed,
    required this.onReveal,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: _buildTextSpan(context),
      textAlign: TextAlign.justify,
    );
  }

  TextSpan _buildTextSpan(BuildContext context) {
    final spans = <InlineSpan>[];
    int lastIndex = 0;
    
    // Sort redacted sections by position
    final sortedSections = List<RedactedContent>.from(redactedSections)
      ..sort((a, b) => a.position.compareTo(b.position));
    
    for (final section in sortedSections) {
      // Add text before redaction
      if (section.position > lastIndex) {
        spans.add(TextSpan(
          text: content.substring(lastIndex, section.position),
          style: Theme.of(context).textTheme.bodyLarge,
        ));
      }
      
      // Add redacted content widget
      spans.add(WidgetSpan(
        child: RedactedContentWidget(
          redactedContent: section,
          isRevealed: isRevealed(section),
          onReveal: () => onReveal(section),
        ),
      ));
      
      lastIndex = section.position + section.hiddenText.length;
    }
    
    // Add remaining text
    if (lastIndex < content.length) {
      spans.add(TextSpan(
        text: content.substring(lastIndex),
        style: Theme.of(context).textTheme.bodyLarge,
      ));
    }
    
    return TextSpan(children: spans);
  }
}

// Helper widget for redaction summary
class RedactionSummaryWidget extends StatelessWidget {
  final List<RedactedContent> redactedSections;
  final int revealedCount;
  final RevealLevel currentLevel;

  const RedactionSummaryWidget({
    super.key,
    required this.redactedSections,
    required this.revealedCount,
    required this.currentLevel,
  });

  @override
  Widget build(BuildContext context) {
    final totalRedactions = redactedSections.length;
    final availableToReveal = redactedSections
        .where((section) => section.revealLevel.level <= currentLevel.level)
        .length;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.security,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            'Classified Content: $revealedCount/$availableToReveal revealed',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (availableToReveal < totalRedactions) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.lock,
              size: 12,
              color: Colors.red[400],
            ),
            Text(
              ' (${totalRedactions - availableToReveal} locked)',
              style: TextStyle(
                fontSize: 10,
                color: Colors.red[400],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}