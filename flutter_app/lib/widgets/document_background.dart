import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import 'dart:math' as math;

class DocumentBackground extends StatefulWidget {
  final Size pageSize;
  final DocumentType documentType;
  final bool supernaturalMode;

  const DocumentBackground({
    super.key,
    required this.pageSize,
    this.documentType = DocumentType.academic,
    this.supernaturalMode = false,
  });

  @override
  State<DocumentBackground> createState() => _DocumentBackgroundState();
}

class _DocumentBackgroundState extends State<DocumentBackground>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _glowController;
  late AnimationController _pulseController;
  
  late Animation<double> _particleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;
  
  final List<ParticleData> _particles = [];
  final List<SpiritParticle> _spiritParticles = [];

  @override
  void initState() {
    super.initState();
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_particleController);
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _initializeParticles();
    _particleController.repeat();
    
    if (widget.supernaturalMode) {
      _glowController.repeat(reverse: true);
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(DocumentBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.supernaturalMode != oldWidget.supernaturalMode) {
      if (widget.supernaturalMode) {
        _initializeSpiritParticles();
        _glowController.repeat(reverse: true);
        _pulseController.repeat(reverse: true);
      } else {
        _spiritParticles.clear();
        _glowController.stop();
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    _glowController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _initializeParticles() {
    _particles.clear();
    final random = math.Random();
    
    // Create floating dust particles
    for (int i = 0; i < 50; i++) {
      _particles.add(ParticleData(
        x: random.nextDouble() * widget.pageSize.width,
        y: random.nextDouble() * widget.pageSize.height,
        size: random.nextDouble() * 2 + 1,
        speed: random.nextDouble() * 0.5 + 0.1,
        opacity: random.nextDouble() * 0.3 + 0.1,
        angle: random.nextDouble() * 2 * math.pi,
      ));
    }
  }

  void _initializeSpiritParticles() {
    _spiritParticles.clear();
    final random = math.Random();
    
    // Create supernatural spirit particles
    for (int i = 0; i < 20; i++) {
      _spiritParticles.add(SpiritParticle(
        x: random.nextDouble() * widget.pageSize.width,
        y: random.nextDouble() * widget.pageSize.height,
        size: random.nextDouble() * 4 + 2,
        speed: random.nextDouble() * 0.3 + 0.05,
        opacity: random.nextDouble() * 0.4 + 0.2,
        angle: random.nextDouble() * 2 * math.pi,
        color: _getRandomSpiritColor(random),
        phase: random.nextDouble() * 2 * math.pi,
      ));
    }
  }

  Color _getRandomSpiritColor(math.Random random) {
    final colors = [
      Colors.purple.withOpacity(0.3),
      Colors.indigo.withOpacity(0.3),
      Colors.deepPurple.withOpacity(0.3),
      Colors.blue.withOpacity(0.2),
    ];
    return colors[random.nextInt(colors.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.pageSize.width,
      height: widget.pageSize.height,
      decoration: BoxDecoration(
        // Base paper color
        color: _getBaseColor(),
        
        // Paper texture gradient
        gradient: _getBackgroundGradient(),
        
        // Subtle border for realism
        border: Border.all(
          color: Colors.black.withOpacity(0.1),
          width: 0.5,
        ),
        
        // Slight shadow for depth
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Paper grain texture overlay
          _buildPaperTexture(),
          
          // Age spots and stains
          _buildAgeEffects(),
          
          // Document-specific elements
          _buildDocumentSpecificElements(),
          
          // Particle effects
          AnimatedBuilder(
            animation: _particleAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(
                  particles: _particles,
                  spiritParticles: _spiritParticles,
                  animation: _particleAnimation.value,
                  supernaturalMode: widget.supernaturalMode,
                ),
                size: widget.pageSize,
              );
            },
          ),
          
          // Supernatural glow overlay
          if (widget.supernaturalMode)
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.0,
                      colors: [
                        Colors.purple.withOpacity(0.1 * _glowAnimation.value),
                        Colors.indigo.withOpacity(0.05 * _glowAnimation.value),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                  ),
                );
              },
            ),
          
          // Pulsing border effect for supernatural mode
          if (widget.supernaturalMode)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.purple.withOpacity(0.2 * _pulseAnimation.value),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Color _getBaseColor() {
    switch (widget.documentType) {
      case DocumentType.academic:
        return AppTheme.academicPaper;
      case DocumentType.personalLetter:
        return AppTheme.personalLetter;
      case DocumentType.policeReport:
        return AppTheme.policeReport;
      case DocumentType.journal:
        return AppTheme.journalPaper;
      case DocumentType.governmentMemo:
        return AppTheme.governmentMemo;
    }
  }

  LinearGradient _getBackgroundGradient() {
    switch (widget.documentType) {
      case DocumentType.academic:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.academicPaper,
            AppTheme.academicPaperDark,
          ],
        );
      default:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getBaseColor(),
            _getBaseColor().withOpacity(0.9),
          ],
        );
    }
  }

  Widget _buildPaperTexture() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.15,
        child: Container(
          decoration: BoxDecoration(
            // Simulate paper fiber texture with a subtle pattern
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 2.0,
              colors: [
                Colors.brown.withOpacity(0.1),
                Colors.transparent,
                Colors.brown.withOpacity(0.05),
                Colors.transparent,
              ],
              stops: const [0.0, 0.25, 0.75, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgeEffects() {
    return Positioned.fill(
      child: Stack(
        children: [
          // Corner age spots
          Positioned(
            top: 8,
            right: 12,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.brown.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          Positioned(
            bottom: 15,
            left: 8,
            child: Container(
              width: 4,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.brown.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Subtle edge darkening
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.topRight,
                  colors: [
                    Colors.transparent,
                    Colors.brown.withOpacity(0.05),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSpecificElements() {
    switch (widget.documentType) {
      case DocumentType.governmentMemo:
        return _buildClassifiedWatermark();
      case DocumentType.journal:
        return _buildJournalLines();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildClassifiedWatermark() {
    return Positioned.fill(
      child: Center(
        child: Transform.rotate(
          angle: -0.3,
          child: Opacity(
            opacity: 0.08,
            child: Text(
              'CLASSIFIED',
              style: TextStyle(
                fontSize: widget.pageSize.width * 0.15,
                fontWeight: FontWeight.bold,
                color: AppTheme.classificationRed,
                letterSpacing: 8,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJournalLines() {
    return Positioned.fill(
      child: CustomPaint(
        painter: JournalLinesPainter(),
      ),
    );
  }
}

enum DocumentType {
  academic,
  personalLetter,
  policeReport,
  journal,
  governmentMemo,
}

class JournalLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..strokeWidth = 0.5;

    final lineSpacing = 24.0;
    final marginLeft = size.width * 0.12;
    final marginRight = size.width * 0.12;
    final startY = 40.0;

    // Draw horizontal lines
    for (double y = startY; y < size.height - 20; y += lineSpacing) {
      canvas.drawLine(
        Offset(marginLeft, y),
        Offset(size.width - marginRight, y),
        paint,
      );
    }

    // Draw margin line
    final marginPaint = Paint()
      ..color = Colors.red.withOpacity(0.4)
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(marginLeft + 30, 20),
      Offset(marginLeft + 30, size.height - 20),
      marginPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ParticleData {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;
  double angle;

  ParticleData({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.angle,
  });
}

class SpiritParticle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;
  double angle;
  final Color color;
  final double phase;

  SpiritParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.angle,
    required this.color,
    required this.phase,
  });
}

class ParticlePainter extends CustomPainter {
  final List<ParticleData> particles;
  final List<SpiritParticle> spiritParticles;
  final double animation;
  final bool supernaturalMode;

  ParticlePainter({
    required this.particles,
    required this.spiritParticles,
    required this.animation,
    required this.supernaturalMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Paint dust particles
    for (final particle in particles) {
      _updateParticle(particle, size);
      _paintParticle(canvas, particle, Colors.brown.withOpacity(0.2));
    }

    // Paint spirit particles in supernatural mode
    if (supernaturalMode) {
      for (final spirit in spiritParticles) {
        _updateSpiritParticle(spirit, size);
        _paintSpiritParticle(canvas, spirit);
      }
    }
  }

  void _updateParticle(ParticleData particle, Size size) {
    particle.x += math.cos(particle.angle) * particle.speed;
    particle.y += math.sin(particle.angle) * particle.speed;

    // Wrap around edges
    if (particle.x > size.width) particle.x = 0;
    if (particle.x < 0) particle.x = size.width;
    if (particle.y > size.height) particle.y = 0;
    if (particle.y < 0) particle.y = size.height;
  }

  void _updateSpiritParticle(SpiritParticle spirit, Size size) {
    // Floating motion with sine wave
    spirit.x += math.cos(spirit.angle + spirit.phase) * spirit.speed;
    spirit.y += math.sin(spirit.angle + spirit.phase * 0.7) * spirit.speed * 0.5;

    // Gentle vertical drift
    spirit.y -= 0.1;

    // Wrap around edges
    if (spirit.x > size.width) spirit.x = 0;
    if (spirit.x < 0) spirit.x = size.width;
    if (spirit.y > size.height) spirit.y = 0;
    if (spirit.y < 0) spirit.y = size.height;
  }

  void _paintParticle(Canvas canvas, ParticleData particle, Color color) {
    final paint = Paint()
      ..color = color.withOpacity(particle.opacity)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(particle.x, particle.y),
      particle.size,
      paint,
    );
  }

  void _paintSpiritParticle(Canvas canvas, SpiritParticle spirit) {
    // Main spirit orb
    final paint = Paint()
      ..color = spirit.color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(spirit.x, spirit.y),
      spirit.size,
      paint,
    );

    // Glowing halo
    final haloPaint = Paint()
      ..color = spirit.color.withOpacity(spirit.opacity * 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(spirit.x, spirit.y),
      spirit.size * 2,
      haloPaint,
    );

    // Wispy trail
    final trailPaint = Paint()
      ..color = spirit.color.withOpacity(spirit.opacity * 0.1)
      ..style = PaintingStyle.fill;

    for (int i = 1; i <= 3; i++) {
      final trailX = spirit.x - (math.cos(spirit.angle) * i * 2);
      final trailY = spirit.y - (math.sin(spirit.angle) * i * 2);
      
      canvas.drawCircle(
        Offset(trailX, trailY),
        spirit.size * (1 - i * 0.2),
        trailPaint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.animation != animation ||
           oldDelegate.supernaturalMode != supernaturalMode;
  }
}

class PaperTexturePainter extends CustomPainter {
  final bool supernaturalMode;

  PaperTexturePainter({this.supernaturalMode = false});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // Fixed seed for consistent texture
    
    // Paper fiber texture
    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final length = random.nextDouble() * 10 + 5;
      final angle = random.nextDouble() * 2 * math.pi;
      
      final paint = Paint()
        ..color = supernaturalMode
            ? Colors.purple.withOpacity(0.02)
            : Colors.brown.withOpacity(0.03)
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke;
      
      canvas.drawLine(
        Offset(x, y),
        Offset(
          x + math.cos(angle) * length,
          y + math.sin(angle) * length,
        ),
        paint,
      );
    }
    
    // Age spots and stains
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 3 + 1;
      
      final paint = Paint()
        ..color = supernaturalMode
            ? Colors.indigo.withOpacity(0.02)
            : Colors.amber.withOpacity(0.05)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
    
    // Subtle edge darkening for supernatural mode
    if (supernaturalMode) {
      final edgePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.center,
          end: Alignment.topRight,
          colors: [
            Colors.transparent,
            Colors.purple.withOpacity(0.05),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        edgePaint,
      );
    }
  }

  @override
  bool shouldRepaint(PaperTexturePainter oldDelegate) {
    return oldDelegate.supernaturalMode != supernaturalMode;
  }
}