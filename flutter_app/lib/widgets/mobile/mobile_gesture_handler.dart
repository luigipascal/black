import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class MobileGestureHandler extends StatefulWidget {
  final Widget child;
  final Function(Offset)? onTap;
  final Function(Offset)? onDoubleTap;
  final Function(Offset)? onLongPress;
  final Function(DragStartDetails)? onPanStart;
  final Function(DragUpdateDetails)? onPanUpdate;
  final Function(DragEndDetails)? onPanEnd;
  final Function(ScaleStartDetails)? onScaleStart;
  final Function(ScaleUpdateDetails)? onScaleUpdate;
  final Function(ScaleEndDetails)? onScaleEnd;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final bool enableHapticFeedback;
  final bool enableSwipeDetection;
  final bool enableScaling;
  final double swipeThreshold;
  
  const MobileGestureHandler({
    super.key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeUp,
    this.onSwipeDown,
    this.enableHapticFeedback = true,
    this.enableSwipeDetection = true,
    this.enableScaling = true,
    this.swipeThreshold = 100.0,
  });

  @override
  State<MobileGestureHandler> createState() => _MobileGestureHandlerState();
}

class _MobileGestureHandlerState extends State<MobileGestureHandler> {
  Offset? _panStartPosition;
  bool _isScaling = false;
  double _lastScale = 1.0;
  
  void _triggerHapticFeedback(HapticFeedbackType type) {
    if (!widget.enableHapticFeedback) return;
    
    switch (type) {
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selection:
        HapticFeedback.selectionClick();
        break;
    }
  }
  
  void _triggerCustomVibration(int duration) async {
    if (!widget.enableHapticFeedback) return;
    
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(duration: duration);
    } else {
      HapticFeedback.lightImpact();
    }
  }
  
  void _handleTap(TapUpDetails details) {
    _triggerHapticFeedback(HapticFeedbackType.light);
    widget.onTap?.call(details.localPosition);
  }
  
  void _handleDoubleTap() {
    _triggerHapticFeedback(HapticFeedbackType.medium);
    widget.onDoubleTap?.call(Offset.zero);
  }
  
  void _handleLongPress(LongPressStartDetails details) {
    _triggerCustomVibration(50);
    widget.onLongPress?.call(details.localPosition);
  }
  
  void _handlePanStart(DragStartDetails details) {
    _panStartPosition = details.localPosition;
    _isScaling = false;
    widget.onPanStart?.call(details);
  }
  
  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isScaling) return;
    widget.onPanUpdate?.call(details);
  }
  
  void _handlePanEnd(DragEndDetails details) {
    if (_panStartPosition == null || _isScaling) return;
    
    final velocity = details.velocity.pixelsPerSecond;
    final magnitude = velocity.distance;
    
    if (widget.enableSwipeDetection && magnitude > 800) {
      final direction = velocity / magnitude;
      
      if (direction.dx.abs() > direction.dy.abs()) {
        // Horizontal swipe
        if (direction.dx > 0) {
          _triggerHapticFeedback(HapticFeedbackType.selection);
          widget.onSwipeRight?.call();
        } else {
          _triggerHapticFeedback(HapticFeedbackType.selection);
          widget.onSwipeLeft?.call();
        }
      } else {
        // Vertical swipe
        if (direction.dy > 0) {
          _triggerHapticFeedback(HapticFeedbackType.selection);
          widget.onSwipeDown?.call();
        } else {
          _triggerHapticFeedback(HapticFeedbackType.selection);
          widget.onSwipeUp?.call();
        }
      }
    }
    
    widget.onPanEnd?.call(details);
    _panStartPosition = null;
  }
  
  void _handleScaleStart(ScaleStartDetails details) {
    if (!widget.enableScaling) return;
    
    _isScaling = true;
    _lastScale = details.scale;
    _triggerHapticFeedback(HapticFeedbackType.light);
    widget.onScaleStart?.call(details);
  }
  
  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (!widget.enableScaling) return;
    
    // Trigger haptic feedback for significant scale changes
    final scaleDiff = (details.scale - _lastScale).abs();
    if (scaleDiff > 0.1) {
      _triggerHapticFeedback(HapticFeedbackType.light);
      _lastScale = details.scale;
    }
    
    widget.onScaleUpdate?.call(details);
  }
  
  void _handleScaleEnd(ScaleEndDetails details) {
    if (!widget.enableScaling) return;
    
    _isScaling = false;
    _triggerHapticFeedback(HapticFeedbackType.medium);
    widget.onScaleEnd?.call(details);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: _handleTap,
      onDoubleTap: _handleDoubleTap,
      onLongPressStart: _handleLongPress,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      onScaleStart: widget.enableScaling ? _handleScaleStart : null,
      onScaleUpdate: widget.enableScaling ? _handleScaleUpdate : null,
      onScaleEnd: widget.enableScaling ? _handleScaleEnd : null,
      child: widget.child,
    );
  }
}

enum HapticFeedbackType {
  light,
  medium,
  heavy,
  selection,
}

// Specialized gesture widgets
class SwipePageHandler extends StatelessWidget {
  final Widget child;
  final VoidCallback? onNextPage;
  final VoidCallback? onPreviousPage;
  final bool enableHapticFeedback;
  
  const SwipePageHandler({
    super.key,
    required this.child,
    this.onNextPage,
    this.onPreviousPage,
    this.enableHapticFeedback = true,
  });

  @override
  Widget build(BuildContext context) {
    return MobileGestureHandler(
      enableHapticFeedback: enableHapticFeedback,
      onSwipeLeft: onNextPage,
      onSwipeRight: onPreviousPage,
      child: child,
    );
  }
}

class ZoomablePageHandler extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final bool enableHapticFeedback;
  
  const ZoomablePageHandler({
    super.key,
    required this.child,
    this.minScale = 0.8,
    this.maxScale = 3.0,
    this.enableHapticFeedback = true,
  });

  @override
  State<ZoomablePageHandler> createState() => _ZoomablePageHandlerState();
}

class _ZoomablePageHandlerState extends State<ZoomablePageHandler>
    with TickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onDoubleTap(Offset position) {
    if (widget.enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }
    
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final targetScale = currentScale > 1.5 ? 1.0 : 2.0;
    
    final targetMatrix = Matrix4.identity()
      ..translate(-position.dx * (targetScale - 1), -position.dy * (targetScale - 1))
      ..scale(targetScale);
    
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _animation!.addListener(() {
      _transformationController.value = _animation!.value;
    });
    
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: widget.minScale,
      maxScale: widget.maxScale,
      onInteractionStart: (details) {
        if (widget.enableHapticFeedback && details.pointerCount > 1) {
          HapticFeedback.lightImpact();
        }
      },
      child: MobileGestureHandler(
        enableHapticFeedback: widget.enableHapticFeedback,
        enableScaling: false, // InteractiveViewer handles scaling
        onDoubleTap: _onDoubleTap,
        child: widget.child,
      ),
    );
  }
}

class AnnotationGestureHandler extends StatelessWidget {
  final Widget child;
  final Function(Offset)? onTap;
  final Function(Offset)? onLongPress;
  final Function(DragStartDetails)? onDragStart;
  final Function(DragUpdateDetails)? onDragUpdate;
  final Function(DragEndDetails)? onDragEnd;
  final bool enableHapticFeedback;
  
  const AnnotationGestureHandler({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.enableHapticFeedback = true,
  });

  @override
  Widget build(BuildContext context) {
    return MobileGestureHandler(
      enableHapticFeedback: enableHapticFeedback,
      enableSwipeDetection: false,
      enableScaling: false,
      onTap: onTap,
      onLongPress: onLongPress,
      onPanStart: onDragStart,
      onPanUpdate: onDragUpdate,
      onPanEnd: onDragEnd,
      child: child,
    );
  }
}

// Utility class for gesture settings
class GestureSettings {
  static bool _hapticEnabled = true;
  static double _swipeThreshold = 100.0;
  static double _longPressThreshold = 500.0;
  
  static bool get hapticEnabled => _hapticEnabled;
  static double get swipeThreshold => _swipeThreshold;
  static double get longPressThreshold => _longPressThreshold;
  
  static void setHapticEnabled(bool enabled) {
    _hapticEnabled = enabled;
  }
  
  static void setSwipeThreshold(double threshold) {
    _swipeThreshold = threshold;
  }
  
  static void setLongPressThreshold(double threshold) {
    _longPressThreshold = threshold;
  }
  
  static void loadFromPreferences(Map<String, dynamic> preferences) {
    _hapticEnabled = preferences['haptic_enabled'] ?? true;
    _swipeThreshold = preferences['swipe_threshold'] ?? 100.0;
    _longPressThreshold = preferences['long_press_threshold'] ?? 500.0;
  }
  
  static Map<String, dynamic> toPreferences() {
    return {
      'haptic_enabled': _hapticEnabled,
      'swipe_threshold': _swipeThreshold,
      'long_press_threshold': _longPressThreshold,
    };
  }
}