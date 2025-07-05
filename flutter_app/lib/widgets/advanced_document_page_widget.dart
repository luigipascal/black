import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class AdvancedDocumentPageWidget extends StatefulWidget {
  final String content;
  final List<Map<String, dynamic>> annotations;
  final bool isDarkMode;

  const AdvancedDocumentPageWidget({
    Key? key,
    required this.content,
    required this.annotations,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  State<AdvancedDocumentPageWidget> createState() => _AdvancedDocumentPageWidgetState();
}

class _AdvancedDocumentPageWidgetState extends State<AdvancedDocumentPageWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _pageController;
  late AnimationController _particleController;
  late AnimationController _candlelightController;
  late AnimationController _supernaturalController;
  
  final List<Particle> _particles = [];
  final List<SpiritParticle> _spiritParticles = [];
  bool _isPageTurning = false;
  bool _supernaturalMode = false;
  Offset _mousePosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    
    _pageController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    _candlelightController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _supernaturalController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _initializeParticles();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _particleController.dispose();
    _candlelightController.dispose();
    _supernaturalController.dispose();
    super.dispose();
  }

  void _initializeParticles() {
    final random = math.Random();
    
    // Create floating particles
    for (int i = 0; i < 50; i++) {
      _particles.add(Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        speed: random.nextDouble() * 0.02 + 0.01,
        size: random.nextDouble() * 3 + 1,
        opacity: random.nextDouble() * 0.5 + 0.3,
      ));
    }
    
    // Create spirit particles for supernatural mode
    for (int i = 0; i < 20; i++) {
      _spiritParticles.add(SpiritParticle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        speed: random.nextDouble() * 0.01 + 0.005,
        size: random.nextDouble() * 4 + 2,
        phase: random.nextDouble() * math.pi * 2,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        setState(() {
          _mousePosition = event.localPosition;
        });
      },
      child: Stack(
        children: [
          // Candlelight background effect
          _buildCandlelightBackground(),
          
          // Particle system
          _buildParticleSystem(),
          
          // 3D Book page
          _build3DPage(),
          
          // Floating annotations
          ..._buildFloatingAnnotations(),
          
          // Supernatural overlay
          if (_supernaturalMode) _buildSupernaturalOverlay(),
          
          // Controls
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildCandlelightBackground() {
    return AnimatedBuilder(
      animation: _candlelightController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                (_mousePosition.dx / MediaQuery.of(context).size.width) * 2 - 1,
                (_mousePosition.dy / MediaQuery.of(context).size.height) * 2 - 1,
              ),
              radius: 1.0,
              colors: widget.isDarkMode
                  ? [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.8),
                    ]
                  : [
                      const Color(0xFFF4F1E8),
                      const Color(0xFFE8E1D3),
                      const Color(0xFFD4C4A8),
                      const Color(0xFFC4B494),
                    ],
              stops: const [0.0, 0.3, 0.6, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticleSystem() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticleSystemPainter(
            particles: _particles,
            spiritParticles: _spiritParticles,
            animation: _particleController.value,
            supernaturalMode: _supernaturalMode,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _build3DPage() {
    return Center(
      child: AnimatedBuilder(
        animation: _pageController,
        builder: (context, child) {
          final rotationY = _pageController.value * math.pi;
          
          return Transform(
            alignment: Alignment.centerLeft,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspective
              ..rotateY(rotationY),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 600,
              height: 800,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.isDarkMode
                      ? [const Color(0xFF2D1810), const Color(0xFF1A1A1A)]
                      : [const Color(0xFFF4F1E8), const Color(0xFFE8E1D3)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                  if (_supernaturalMode)
                    BoxShadow(
                      color: const Color(0xFF9D4EDD).withOpacity(0.5),
                      blurRadius: 30,
                      offset: const Offset(0, 0),
                    ),
                ],
              ),
              child: _buildPageContent(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageContent() {
    return AnimatedBuilder(
      animation: _supernaturalController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chapter title with glow effect
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                padding: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _supernaturalMode
                          ? const Color(0xFF9D4EDD).withOpacity(0.6)
                          : Colors.black.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  'Chapter I: Introduction and Historical Context',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                    shadows: _supernaturalMode
                        ? [
                            const Shadow(
                              color: Color(0xFF9D4EDD),
                              blurRadius: 10,
                              offset: Offset(0, 0),
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Content with redacted text
              Expanded(
                child: SingleChildScrollView(
                  child: _buildRichText(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRichText() {
    final List<TextSpan> spans = [];
    final content = widget.content;
    
    // Parse content and handle redacted sections
    final redactionPattern = RegExp(r'████████');
    final matches = redactionPattern.allMatches(content);
    
    int lastIndex = 0;
    for (final match in matches) {
      // Add text before redaction
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: content.substring(lastIndex, match.start),
          style: _getContentTextStyle(),
        ));
      }
      
      // Add redacted content with special styling
      spans.add(TextSpan(
        text: match.group(0)!,
        style: _getRedactedTextStyle(),
        recognizer: TapGestureRecognizer()
          ..onTap = () => _revealRedactedContent(match.start),
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

  List<Widget> _buildFloatingAnnotations() {
    return widget.annotations.asMap().entries.map((entry) {
      final index = entry.key;
      final annotation = entry.value;
      
      return AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          final floatOffset = math.sin(_particleController.value * 2 * math.pi + index) * 8;
          
          return Positioned(
            left: annotation['x'] * 500 + 50,
            top: annotation['y'] * 600 + 100 + floatOffset,
            child: GestureDetector(
              onTap: () => _onAnnotationTap(annotation),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                transform: Matrix4.identity()
                  ..translate(0.0, floatOffset, 0.0)
                  ..scale(_supernaturalMode ? 1.1 : 1.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getAnnotationColor(annotation['character']),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                      if (_supernaturalMode)
                        BoxShadow(
                          color: const Color(0xFF9D4EDD).withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 0),
                        ),
                    ],
                  ),
                  child: Text(
                    annotation['text'],
                    style: TextStyle(
                      fontSize: 12,
                      color: _getAnnotationTextColor(annotation['character']),
                      fontFamily: _getAnnotationFont(annotation['character']),
                      shadows: _supernaturalMode
                          ? [
                              const Shadow(
                                color: Color(0xFF9D4EDD),
                                blurRadius: 5,
                                offset: Offset(0, 0),
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildSupernaturalOverlay() {
    return AnimatedBuilder(
      animation: _supernaturalController,
      builder: (context, child) {
        final pulseOpacity = (math.sin(_supernaturalController.value * 2 * math.pi) + 1) / 2;
        
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                const Color(0xFF9D4EDD).withOpacity(pulseOpacity * 0.1),
                const Color(0xFF9D4EDD).withOpacity(pulseOpacity * 0.05),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Positioned(
      top: 50,
      right: 50,
      child: Column(
        children: [
          FloatingActionButton(
            heroTag: "dark_mode",
            onPressed: _toggleSupernaturalMode,
            backgroundColor: _supernaturalMode 
                ? const Color(0xFF9D4EDD) 
                : const Color(0xFFFF8C42),
            child: Icon(_supernaturalMode ? Icons.auto_fix_high : Icons.auto_fix_normal),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "page_turn",
            onPressed: _turnPage,
            backgroundColor: const Color(0xFF654321),
            child: const Icon(Icons.flip_to_front),
          ),
        ],
      ),
    );
  }

  // Helper methods
  TextStyle _getContentTextStyle() {
    return TextStyle(
      fontSize: 14,
      height: 1.6,
      color: widget.isDarkMode ? Colors.white.withOpacity(0.9) : Colors.black87,
      fontFamily: 'Georgia',
    );
  }

  TextStyle _getRedactedTextStyle() {
    return TextStyle(
      fontSize: 14,
      height: 1.6,
      backgroundColor: Colors.black87,
      color: Colors.transparent,
    );
  }

  Color _getAnnotationColor(String character) {
    switch (character) {
      case 'MB': return const Color(0xFFFFF68F);
      case 'JR': return Colors.white.withOpacity(0.9);
      case 'SW': return const Color(0xFFFFF68F);
      default: return Colors.white.withOpacity(0.9);
    }
  }

  Color _getAnnotationTextColor(String character) {
    switch (character) {
      case 'MB': return const Color(0xFF2653A3);
      case 'JR': return Colors.black87;
      case 'SW': return const Color(0xFF654321);
      default: return Colors.black87;
    }
  }

  String _getAnnotationFont(String character) {
    switch (character) {
      case 'MB': return 'Cursive';
      case 'JR': return 'Courier';
      case 'SW': return 'Courier';
      default: return 'Georgia';
    }
  }

  // Event handlers
  void _toggleSupernaturalMode() {
    setState(() {
      _supernaturalMode = !_supernaturalMode;
    });
    
    HapticFeedback.mediumImpact();
    
    if (_supernaturalMode) {
      _supernaturalController.repeat(reverse: true);
    } else {
      _supernaturalController.stop();
    }
  }

  void _turnPage() {
    if (!_isPageTurning) {
      setState(() {
        _isPageTurning = true;
      });
      
      _pageController.forward().then((_) {
        _pageController.reverse().then((_) {
          setState(() {
            _isPageTurning = false;
          });
        });
      });
    }
  }

  void _onAnnotationTap(Map<String, dynamic> annotation) {
    HapticFeedback.lightImpact();
    
    showDialog(
      context: context,
      builder: (context) => _buildAnnotationDialog(annotation),
    );
  }

  Widget _buildAnnotationDialog(Map<String, dynamic> annotation) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2D1810),
              const Color(0xFF1A1A1A),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9D4EDD).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              annotation['character'],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              annotation['text'],
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9D4EDD),
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _revealRedactedContent(int position) {
    setState(() {
      _supernaturalMode = true;
    });
    
    HapticFeedback.heavyImpact();
    
    // Show revelation animation
    _supernaturalController.repeat(reverse: true);
  }
}

// Particle classes
class Particle {
  double x, y, speed, size, opacity;
  
  Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
  });
}

class SpiritParticle {
  double x, y, speed, size, phase;
  
  SpiritParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.phase,
  });
}

// Custom painter for particle system
class ParticleSystemPainter extends CustomPainter {
  final List<Particle> particles;
  final List<SpiritParticle> spiritParticles;
  final double animation;
  final bool supernaturalMode;

  ParticleSystemPainter({
    required this.particles,
    required this.spiritParticles,
    required this.animation,
    required this.supernaturalMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Draw regular particles
    for (final particle in particles) {
      final x = particle.x * size.width;
      final y = (particle.y - animation * particle.speed) * size.height;
      
      if (y < -particle.size) continue;
      
      paint.color = const Color(0xFF9D4EDD).withOpacity(particle.opacity);
      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
    
    // Draw spirit particles in supernatural mode
    if (supernaturalMode) {
      for (final spirit in spiritParticles) {
        final baseX = spirit.x * size.width;
        final baseY = spirit.y * size.height;
        
        final offsetX = math.sin(animation * 2 * math.pi + spirit.phase) * 20;
        final offsetY = math.cos(animation * 2 * math.pi + spirit.phase) * 15;
        
        final x = baseX + offsetX;
        final y = baseY + offsetY;
        
        paint.color = const Color(0xFF9D4EDD).withOpacity(0.7);
        paint.maskFilter = const MaskFilter.blur(BlurStyle.outer, 5);
        
        canvas.drawCircle(Offset(x, y), spirit.size, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Gesture recognizer import
import 'package:flutter/gestures.dart';