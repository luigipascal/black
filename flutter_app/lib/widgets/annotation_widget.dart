import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/document_models.dart';
import '../constants/app_theme.dart';
import '../providers/document_state.dart';
import '../services/content_loader.dart';

class AnnotationWidget extends StatefulWidget {
  final Annotation annotation;
  final Size pageSize;
  final EdgeInsets margins;

  const AnnotationWidget({
    super.key,
    required this.annotation,
    required this.pageSize,
    required this.margins,
  });

  @override
  State<AnnotationWidget> createState() => _AnnotationWidgetState();
}

class _AnnotationWidgetState extends State<AnnotationWidget> {
  late Offset _position;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _position = _calculateInitialPosition();
  }

  Offset _calculateInitialPosition() {
    final pos = widget.annotation.position;
    
    // Convert relative position (0-1) to absolute position
    final x = pos.x * widget.pageSize.width;
    final y = pos.y * widget.pageSize.height;
    
    // Load any saved position for draggable annotations
    if (widget.annotation.isPost2000) {
      final savedPosition = context.read<DocumentState>().getAnnotationPosition(widget.annotation.id);
      if (savedPosition != null) {
        return savedPosition;
      }
    }
    
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.annotation.isPre2000) {
      return _buildFixedMarginalia();
    } else {
      return _buildDraggablePostIt();
    }
  }

  Widget _buildFixedMarginalia() {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onTap: () => _showAnnotationDetail(context),
        onLongPress: () => _showCharacterInfo(context),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: _getMaxWidth(),
            minWidth: 60,
          ),
          child: Transform.rotate(
            angle: widget.annotation.position.rotation,
            child: Text(
              widget.annotation.text,
              style: _getAnnotationStyle(),
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDraggablePostIt() {
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
        onDragStarted: () {
          setState(() {
            _isDragging = true;
          });
        },
        onDragEnd: (details) {
          setState(() {
            _isDragging = false;
            _position = _constrainPosition(details.offset);
          });
          _savePosition();
        },
        child: GestureDetector(
          onTap: () => _showAnnotationDetail(context),
          onLongPress: () => _showCharacterInfo(context),
          child: _buildPostItContent(),
        ),
      ),
    );
  }

  Widget _buildPostItContent({bool isDragging = false}) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: _getMaxWidth(),
        minWidth: 80,
      ),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getPostItColor().withOpacity(isDragging ? 0.8 : 0.9),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDragging ? 0.3 : 0.2),
            blurRadius: isDragging ? 6 : 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Transform.rotate(
        angle: widget.annotation.position.rotation,
        child: _buildPostItText(),
      ),
    );
  }

  Widget _buildPostItText() {
    return Text(
      widget.annotation.text,
      style: _getAnnotationStyle(),
      maxLines: 6,
      overflow: TextOverflow.ellipsis,
    );
  }

  TextStyle _getAnnotationStyle() {
    return CharacterStyles.getStyleForCharacter(widget.annotation.character);
  }

  Color _getPostItColor() {
    switch (widget.annotation.character) {
      case 'SW':
        return AppTheme.postItYellow;
      case 'Detective Sharma':
        return AppTheme.postItWhite;
      case 'Dr. Chambers':
        return AppTheme.postItManila;
      default:
        return AppTheme.postItYellow;
    }
  }

  double _getMaxWidth() {
    switch (widget.annotation.position.zone) {
      case AnnotationZone.leftMargin:
      case AnnotationZone.rightMargin:
        return widget.margins.left - 10;
      case AnnotationZone.topMargin:
      case AnnotationZone.bottomMargin:
        return widget.pageSize.width * 0.4;
      case AnnotationZone.content:
        return widget.pageSize.width * 0.3;
    }
  }

  Offset _constrainPosition(Offset position) {
    final maxWidth = _getMaxWidth();
    final maxHeight = 100.0; // Approximate max annotation height
    
    final maxX = widget.pageSize.width - maxWidth;
    final maxY = widget.pageSize.height - maxHeight;
    
    return Offset(
      position.dx.clamp(0.0, maxX),
      position.dy.clamp(0.0, maxY),
    );
  }

  void _savePosition() {
    if (widget.annotation.isPost2000) {
      context.read<DocumentState>().updateAnnotationPosition(
        widget.annotation.id,
        _position,
      );
    }
  }

  void _showAnnotationDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AnnotationDetailDialog(
        annotation: widget.annotation,
      ),
    );
  }

  void _showCharacterInfo(BuildContext context) {
    final character = ContentLoader.getCharacter(widget.annotation.character);
    if (character == null) return;

    showDialog(
      context: context,
      builder: (context) => CharacterInfoDialog(
        character: character,
        annotation: widget.annotation,
      ),
    );
  }
}

class AnnotationDetailDialog extends StatelessWidget {
  final Annotation annotation;

  const AnnotationDetailDialog({
    super.key,
    required this.annotation,
  });

  @override
  Widget build(BuildContext context) {
    final character = ContentLoader.getCharacter(annotation.character);
    
    return AlertDialog(
      title: Row(
        children: [
          Text(character?.name ?? annotation.character),
          const Spacer(),
          if (annotation.year != null)
            Text(
              '${annotation.year}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            annotation.text,
            style: CharacterStyles.getStyleForCharacter(annotation.character).copyWith(
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                annotation.isPre2000 ? Icons.push_pin : Icons.note,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                annotation.isPre2000 ? 'Fixed Marginalia' : 'Moveable Note',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (character != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (context) => CharacterInfoDialog(
                  character: character,
                  annotation: annotation,
                ),
              );
            },
            child: const Text('About Author'),
          ),
      ],
    );
  }
}

class CharacterInfoDialog extends StatelessWidget {
  final Character character;
  final Annotation annotation;

  const CharacterInfoDialog({
    super.key,
    required this.character,
    required this.annotation,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(character.fullName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                character.role,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                character.years,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            character.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Writing Style:',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  character.annotationStyle.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sample: "${annotation.text.length > 50 ? annotation.text.substring(0, 50) + '...' : annotation.text}"',
                  style: CharacterStyles.getStyleForCharacter(annotation.character),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}