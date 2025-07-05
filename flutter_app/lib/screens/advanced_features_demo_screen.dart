import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../models/enhanced_document_models.dart';
import '../providers/enhanced_revelation_provider.dart';
import '../widgets/advanced_book_reader_widget.dart';
import '../screens/advanced_character_discovery_screen.dart';
import '../screens/enhanced_character_timeline_screen.dart';

class AdvancedFeaturesDemoScreen extends StatefulWidget {
  const AdvancedFeaturesDemoScreen({super.key});

  @override
  State<AdvancedFeaturesDemoScreen> createState() => _AdvancedFeaturesDemoScreenState();
}

class _AdvancedFeaturesDemoScreenState extends State<AdvancedFeaturesDemoScreen>
    with TickerProviderStateMixin {
  late AnimationController _demoController;
  late AnimationController _featureController;
  late Animation<double> _demoAnimation;
  late Animation<double> _featureAnimation;
  
  int _currentFeature = 0;
  bool _darkMode = false;
  bool _supernaturalMode = false;
  
  final List<DemoFeature> _features = [
    DemoFeature(
      title: '3D Page Transitions',
      description: 'Realistic book page turning with 3D perspective transforms',
      icon: Icons.flip_to_front,
      color: Colors.blue,
      demoWidget: null,
    ),
    DemoFeature(
      title: 'Particle Effects',
      description: 'Atmospheric floating particles and supernatural elements',
      icon: Icons.blur_on,
      color: Colors.purple,
      demoWidget: null,
    ),
    DemoFeature(
      title: 'Advanced Search',
      description: 'Real-time search across annotations, characters, and content',
      icon: Icons.search,
      color: Colors.green,
      demoWidget: null,
    ),
    DemoFeature(
      title: 'Character Discovery',
      description: 'Interactive character timeline with missing persons tracking',
      icon: Icons.people,
      color: Colors.orange,
      demoWidget: null,
    ),
    DemoFeature(
      title: 'Supernatural Mode',
      description: 'Progressive revelation system with atmospheric effects',
      icon: Icons.visibility,
      color: Colors.red,
      demoWidget: null,
    ),
    DemoFeature(
      title: 'Analytics Dashboard',
      description: 'Reading progress tracking with discovery statistics',
      icon: Icons.analytics,
      color: Colors.teal,
      demoWidget: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    _demoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _featureController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _demoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _demoController,
      curve: Curves.easeInOut,
    ));
    
    _featureAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _featureController,
      curve: Curves.elasticOut,
    ));
    
    _demoController.forward();
    _featureController.forward();
  }

  @override
  void dispose() {
    _demoController.dispose();
    _featureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedRevelationProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: _darkMode ? Colors.black : Colors.grey[50],
          appBar: _buildDemoAppBar(),
          body: AnimatedBuilder(
            animation: _demoAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                  // Background effects
                  _buildBackgroundEffects(),
                  
                  // Main content
                  _buildMainContent(provider),
                  
                  // Feature overlay
                  _buildFeatureOverlay(),
                  
                  // Control panel
                  _buildControlPanel(),
                ],
              );
            },
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildDemoAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: AnimatedBuilder(
        animation: _demoAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.8 + (_demoAnimation.value * 0.2),
            child: Text(
              'Phase B3: Advanced UI/UX Demo',
              style: TextStyle(
                fontFamily: 'Crimson Text',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _darkMode ? Colors.white : Colors.black87,
              ),
            ),
          );
        },
      ),
      actions: [
        // Dark mode toggle
        IconButton(
          icon: Icon(
            _darkMode ? Icons.light_mode : Icons.dark_mode,
            color: _darkMode ? Colors.white : Colors.black,
          ),
          onPressed: () {
            setState(() {
              _darkMode = !_darkMode;
            });
            HapticFeedback.lightImpact();
          },
        ),
        
        // Supernatural mode toggle
        IconButton(
          icon: Icon(
            Icons.visibility,
            color: _supernaturalMode ? Colors.purple : (_darkMode ? Colors.white : Colors.black),
          ),
          onPressed: () {
            setState(() {
              _supernaturalMode = !_supernaturalMode;
            });
            HapticFeedback.mediumImpact();
          },
        ),
      ],
    );
  }

  Widget _buildBackgroundEffects() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _demoAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: DemoBackgroundPainter(
              animationValue: _demoAnimation.value,
              darkMode: _darkMode,
              supernaturalMode: _supernaturalMode,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  Widget _buildMainContent(EnhancedRevelationProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Demo introduction
          _buildDemoIntroduction(),
          
          const SizedBox(height: 20),
          
          // Feature showcase
          Expanded(
            child: _buildFeatureShowcase(provider),
          ),
          
          const SizedBox(height: 20),
          
          // Action buttons
          _buildActionButtons(provider),
        ],
      ),
    );
  }

  Widget _buildDemoIntroduction() {
    return AnimatedBuilder(
      animation: _demoAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _demoAnimation.value)),
          child: Opacity(
            opacity: _demoAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (_darkMode ? Colors.grey[900] : Colors.white)?.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _supernaturalMode ? Colors.purple : Colors.grey[300]!,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: _supernaturalMode ? Colors.purple : Colors.blue,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Advanced Features Demonstration',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _darkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Experience the cutting-edge UI/UX features implemented in Phase B3. Each feature enhances the immersive reading experience with advanced animations, particle effects, and interactive elements.',
                    style: TextStyle(
                      fontSize: 14,
                      color: _darkMode ? Colors.white70 : Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureShowcase(EnhancedRevelationProvider provider) {
    return AnimatedBuilder(
      animation: _featureAnimation,
      builder: (context, child) {
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _features.length,
          itemBuilder: (context, index) {
            final feature = _features[index];
            return _buildFeatureCard(feature, index, provider);
          },
        );
      },
    );
  }

  Widget _buildFeatureCard(DemoFeature feature, int index, EnhancedRevelationProvider provider) {
    final isActive = index == _currentFeature;
    
    return AnimatedBuilder(
      animation: _featureAnimation,
      builder: (context, child) {
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _featureAnimation,
          curve: Interval(
            (index * 0.1).clamp(0, 1),
            ((index * 0.1) + 0.3).clamp(0, 1),
            curve: Curves.easeOut,
          ),
        ));
        
        return SlideTransition(
          position: slideAnimation,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _currentFeature = index;
              });
              _triggerFeatureDemo(feature, provider);
              HapticFeedback.mediumImpact();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              transform: Matrix4.identity()
                ..scale(isActive ? 1.05 : 1.0),
              decoration: BoxDecoration(
                color: (_darkMode ? Colors.grey[800] : Colors.white)?.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive
                      ? feature.color
                      : (_supernaturalMode ? Colors.purple : Colors.grey[300]!),
                  width: isActive ? 3 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isActive
                        ? feature.color.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: isActive ? 12 : 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Feature icon
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: feature.color.withOpacity(0.1),
                      child: Icon(
                        feature.icon,
                        color: feature.color,
                        size: 24,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Feature title
                    Text(
                      feature.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _darkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Feature description
                    Expanded(
                      child: Text(
                        feature.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: _darkMode ? Colors.white70 : Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // Demo indicator
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: feature.color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureOverlay() {
    if (_currentFeature < 0 || _currentFeature >= _features.length) {
      return const SizedBox();
    }
    
    final feature = _features[_currentFeature];
    
    return AnimatedBuilder(
      animation: _featureAnimation,
      builder: (context, child) {
        return Positioned(
          top: 100,
          right: 16,
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: feature.color.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: feature.color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Now Demonstrating:',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feature.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlPanel() {
    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _demoAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - _demoAnimation.value)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (_darkMode ? Colors.grey[900] : Colors.white)?.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _supernaturalMode ? Colors.purple : Colors.grey[300]!,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Demo Controls',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _darkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: Icons.skip_previous,
                        onPressed: () {
                          setState(() {
                            _currentFeature = (_currentFeature - 1).clamp(0, _features.length - 1);
                          });
                        },
                      ),
                      _buildControlButton(
                        icon: Icons.play_arrow,
                        onPressed: () {
                          _featureController.reset();
                          _featureController.forward();
                        },
                      ),
                      _buildControlButton(
                        icon: Icons.skip_next,
                        onPressed: () {
                          setState(() {
                            _currentFeature = (_currentFeature + 1).clamp(0, _features.length - 1);
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: (_darkMode ? Colors.grey[800] : Colors.grey[100])?.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _supernaturalMode ? Colors.purple : Colors.grey[300]!,
        ),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: _supernaturalMode ? Colors.purple : (_darkMode ? Colors.white : Colors.black),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildActionButtons(EnhancedRevelationProvider provider) {
    return AnimatedBuilder(
      animation: _demoAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _demoAnimation.value)),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AdvancedBookReaderWidget(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.book),
                  label: const Text('Advanced Reader'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AdvancedCharacterDiscoveryScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.people),
                  label: const Text('Character Discovery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _triggerFeatureDemo(DemoFeature feature, EnhancedRevelationProvider provider) {
    // Trigger different effects based on the feature
    switch (feature.title) {
      case '3D Page Transitions':
        _demoController.reset();
        _demoController.forward();
        break;
      case 'Particle Effects':
        setState(() {
          _supernaturalMode = !_supernaturalMode;
        });
        break;
      case 'Supernatural Mode':
        provider.advanceRevelationLevel();
        break;
      default:
        _featureController.reset();
        _featureController.forward();
    }
  }
}

// Data models
class DemoFeature {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Widget? demoWidget;

  DemoFeature({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.demoWidget,
  });
}

// Custom painter for demo background
class DemoBackgroundPainter extends CustomPainter {
  final double animationValue;
  final bool darkMode;
  final bool supernaturalMode;

  DemoBackgroundPainter({
    required this.animationValue,
    required this.darkMode,
    required this.supernaturalMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: supernaturalMode
          ? [
              Colors.purple.withOpacity(0.1),
              Colors.indigo.withOpacity(0.05),
              Colors.transparent,
            ]
          : [
              Colors.blue.withOpacity(0.1),
              Colors.cyan.withOpacity(0.05),
              Colors.transparent,
            ],
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      ),
    );

    // Animated elements
    final paint = Paint()
      ..color = (supernaturalMode ? Colors.purple : Colors.blue)
          .withOpacity(0.2 * animationValue)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) + (animationValue * 2 * math.pi);
      final x = size.width * 0.5 + math.cos(angle) * size.width * 0.3;
      final y = size.height * 0.5 + math.sin(angle) * size.height * 0.3;

      canvas.drawCircle(
        Offset(x, y),
        10 * animationValue,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(DemoBackgroundPainter oldDelegate) => true;
}