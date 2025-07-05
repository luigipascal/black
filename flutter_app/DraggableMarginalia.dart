import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DraggableMarginalia extends StatelessWidget {
  final String id;
  final Offset initialPos;
  final Widget child;

  const DraggableMarginalia({
    required this.id,
    required this.initialPos,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<MarginaliaProvider>();

    return Positioned(
      left: provider.positions[id]?.dx ?? initialPos.dx,
      top: provider.positions[id]?.dy ?? initialPos.dy,
      child: Draggable(
        feedback: child,
        childWhenDragging: const SizedBox.shrink(),
        onDragEnd: (d) => provider.savePos(id, d.offset),
        child: child,
      ),
    );
  }
}