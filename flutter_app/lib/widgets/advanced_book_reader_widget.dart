import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../models/enhanced_document_models.dart';
import '../providers/enhanced_revelation_provider.dart';
import '../constants/app_theme.dart';
import 'enhanced_document_page_widget.dart';

class AdvancedBookReaderWidget extends StatefulWidget {
  const AdvancedBookReaderWidget({super.key});

  @override
  State<AdvancedBookReaderWidget> createState() => _AdvancedBookReaderWidgetState();
}

class _AdvancedBookReaderWidgetState extends State<AdvancedBookReaderWidget>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _pageFlipController;
  late AnimationController _supernaturalController;
  late AnimationController _searchController;
  late AnimationController _candlelightController;
  
  late Animation<double> _pageFlipAnimation;
  late Animation<double> _supernaturalPulseAnimation;
  late Animation<double> _candlelightFlickerAnimation;
  late Animation<Offset> _searchSlideAnimation;
  
  int _currentPage = 0;
  bool _isFlipping = false;
  bool _searchVisible = false;
  bool _darkMode = false;
  bool _supernaturalMode = false;
  String _searchQuery = '';
  List<SearchResult> _searchResults = [];
  
  final TextEditingController _searchController_text = TextEditingController();
  final List<Particle> _particles = [];
  final List<CandleFlame> _candles = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    _pageFlipController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _supernaturalController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _searchController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _candlelightController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pageFlipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageFlipController,
      curve: Curves.easeInOut,
    ));
    
    _supernaturalPulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _supernaturalController,
      curve: Curves.easeInOut,
    ));
    
    _candlelightFlickerAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _candlelightController,
      curve: Curves.easeInOut,
    ));
    
    _searchSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _searchController,
      curve: Curves.easeInOut,
    ));
    
    _initializeParticles();
    _initializeCandles();
    
    _candlelightController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pageFlipController.dispose();
    _supernaturalController.dispose();
    _searchController.dispose();
    _candlelightController.dispose();
    _searchController_text.dispose();
    super.dispose();
  }

  void _initializeParticles() {
    final random = math.Random();
    _particles.clear();
    
    for (int i = 0; i < 50; i++) {
      _particles.add(Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 3 + 1,
        speed: random.nextDouble() * 0.5 + 0.1,
        opacity: random.nextDouble() * 0.3 + 0.1,
        color: _supernaturalMode 
            ? Colors.purple.withOpacity(0.3)
            : Colors.brown.withOpacity(0.2),
      ));
    }
  }

  void _initializeCandles() {
    _candles.clear();
    if (_darkMode) {
      _candles.addAll([
        CandleFlame(x: 0.1, y: 0.1, intensity: 1.0),
        CandleFlame(x: 0.9, y: 0.1, intensity: 0.8),
        CandleFlame(x: 0.1, y: 0.9, intensity: 0.9),
        CandleFlame(x: 0.9, y: 0.9, intensity: 0.7),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedRevelationProvider>(
      builder: (context, revelationProvider, child) {
        _updateSupernaturalMode(revelationProvider);
        
        return Scaffold(
          backgroundColor: _darkMode ? Colors.black : null,
          body: Stack(
            children: [
              // Background with particle effects
              _buildAnimatedBackground(),
              
              // Main page view with 3D effects
              _build3DPageView(revelationProvider),
              
              // Supernatural overlay effects
              if (_supernaturalMode)
                _buildSupernaturalOverlay(),
              
              // Candlelight effects in dark mode
              if (_darkMode)
                _buildCandlelightEffects(),
              
              // Advanced controls overlay
              _buildAdvancedControls(revelationProvider),
              
              // Search overlay
              _buildSearchOverlay(revelationProvider),
              
              // Floating action buttons
              _buildFloatingControls(revelationProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedBackground() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: Listenable.merge([_supernaturalController, _candlelightController]),
        builder: (context, child) {
          return CustomPaint(
            painter: AdvancedBackgroundPainter(
              particles: _particles,
              candles: _candles,
              supernaturalMode: _supernaturalMode,
              darkMode: _darkMode,
              animationValue: _supernaturalController.value,
              candlelightValue: _candlelightFlickerAnimation.value,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  Widget _build3DPageView(EnhancedRevelationProvider provider) {
    return AnimatedBuilder(
      animation: _pageFlipAnimation,
      builder: (context, child) {
        return PageView.builder(
          controller: _pageController,
          onPageChanged: (page) {
            setState(() {
              _currentPage = page;
            });
            provider.setCurrentPage(page);
            _triggerPageFlipAnimation();
            
            // Haptic feedback
            HapticFeedback.lightImpact();
          },
          itemCount: provider.getTotalPages(),
          itemBuilder: (context, index) {
            return _build3DPage(index, provider);
          },
        );
      },
    );
  }

  Widget _build3DPage(int pageIndex, EnhancedRevelationProvider provider) {
    final isCurrentPage = pageIndex == _currentPage;
    final flipProgress = isCurrentPage ? _pageFlipAnimation.value : 0.0;
    
    return AnimatedBuilder(
      animation: _pageFlipAnimation,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.centerLeft,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Perspective
            ..rotateY(flipProgress * math.pi * 0.1), // 3D rotation
          child: Transform.scale(
            scale: _supernaturalMode ? _supernaturalPulseAnimation.value : 1.0,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _supernaturalMode 
                        ? Colors.purple.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: EnhancedDocumentPageWidget(
                  pageNumber: pageIndex,
                  readingMode: ReadingMode.singlePage,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSupernaturalOverlay() {
    return AnimatedBuilder(
      animation: _supernaturalController,
      builder: (context, child) {
        return Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  Colors.purple.withOpacity(0.1 * _supernaturalController.value),
                  Colors.indigo.withOpacity(0.05 * _supernaturalController.value),
                  Colors.transparent,
                ],
              ),
            ),
            child: CustomPaint(
              painter: SupernaturalEffectsPainter(
                animationValue: _supernaturalController.value,
              ),
              size: Size.infinite,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCandlelightEffects() {
    return AnimatedBuilder(
      animation: _candlelightFlickerAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: CustomPaint(
            painter: CandlelightPainter(
              candles: _candles,
              flickerValue: _candlelightFlickerAnimation.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildAdvancedControls(EnhancedRevelationProvider provider) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Row(
        children: [
          // Reading progress
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: (_darkMode ? Colors.black : Colors.white).withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _supernaturalMode ? Colors.purple : Colors.grey[300]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.book,
                    size: 16,
                    color: _supernaturalMode ? Colors.purple : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_currentPage + 1) / provider.getTotalPages(),
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation(
                        _supernaturalMode ? Colors.purple : Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_currentPage + 1}/${provider.getTotalPages()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _darkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Theme toggle
          _buildControlButton(
            icon: _darkMode ? Icons.light_mode : Icons.dark_mode,
            onPressed: () {
              setState(() {
                _darkMode = !_darkMode;
                _initializeCandles();
              });
            },
          ),
          
          const SizedBox(width: 8),
          
          // Search toggle
          _buildControlButton(
            icon: Icons.search,
            onPressed: () {
              setState(() {
                _searchVisible = !_searchVisible;
              });
              if (_searchVisible) {
                _searchController.forward();
              } else {
                _searchController.reverse();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: (_darkMode ? Colors.black : Colors.white).withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _supernaturalMode ? Colors.purple : Colors.grey[300]!,
        ),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 20,
          color: _supernaturalMode ? Colors.purple : (_darkMode ? Colors.white : Colors.black),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSearchOverlay(EnhancedRevelationProvider provider) {
    return SlideTransition(
      position: _searchSlideAnimation,
      child: Container(
        height: 200,
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 60,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          color: (_darkMode ? Colors.grey[900] : Colors.white)?.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
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
          children: [
            // Search input
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController_text,
                decoration: InputDecoration(
                  hintText: 'Search annotations, characters, or content...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: _supernaturalMode ? Colors.purple : null,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _supernaturalMode ? Colors.purple : Colors.grey[300]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: _supernaturalMode ? Colors.purple : Colors.blue,
                    ),
                  ),
                ),
                style: TextStyle(
                  color: _darkMode ? Colors.white : Colors.black,
                ),
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query;
                  });
                  _performSearch(query, provider);
                },
              ),
            ),
            
            // Search results
            Expanded(
              child: _searchResults.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'Enter search terms to find content'
                            : 'No results found',
                        style: TextStyle(
                          color: _darkMode ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return _buildSearchResultItem(result, provider);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultItem(SearchResult result, EnhancedRevelationProvider provider) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getResultTypeColor(result.type),
        child: Icon(
          _getResultTypeIcon(result.type),
          color: Colors.white,
          size: 16,
        ),
      ),
      title: Text(
        result.title,
        style: TextStyle(
          color: _darkMode ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        result.preview,
        style: TextStyle(
          color: _darkMode ? Colors.white70 : Colors.grey[600],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        'Page ${result.pageNumber}',
        style: TextStyle(
          color: _supernaturalMode ? Colors.purple : Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () {
        _pageController.animateToPage(
          result.pageNumber - 1,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        setState(() {
          _searchVisible = false;
        });
        _searchController.reverse();
      },
    );
  }

  Widget _buildFloatingControls(EnhancedRevelationProvider provider) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Analytics button
          FloatingActionButton(
            heroTag: 'analytics',
            mini: true,
            backgroundColor: _supernaturalMode ? Colors.purple : Colors.blue,
            onPressed: () => _showAnalytics(provider),
            child: const Icon(Icons.analytics, color: Colors.white),
          ),
          
          const SizedBox(height: 8),
          
          // Character timeline button
          FloatingActionButton(
            heroTag: 'timeline',
            mini: true,
            backgroundColor: _supernaturalMode ? Colors.purple : Colors.green,
            onPressed: () => _showCharacterTimeline(provider),
            child: const Icon(Icons.timeline, color: Colors.white),
          ),
          
          const SizedBox(height: 8),
          
          // Export button
          FloatingActionButton(
            heroTag: 'export',
            mini: true,
            backgroundColor: _supernaturalMode ? Colors.purple : Colors.orange,
            onPressed: () => _showExportOptions(provider),
            child: const Icon(Icons.share, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // Helper methods
  void _updateSupernaturalMode(EnhancedRevelationProvider provider) {
    final shouldBeSupernaturalMode = provider.currentRevelationLevel == RevealLevel.completeTruth;
    
    if (shouldBeSupernaturalMode != _supernaturalMode) {
      setState(() {
        _supernaturalMode = shouldBeSupernaturalMode;
        _initializeParticles();
      });
      
      if (_supernaturalMode) {
        _supernaturalController.repeat(reverse: true);
      } else {
        _supernaturalController.stop();
      }
    }
  }

  void _triggerPageFlipAnimation() {
    _pageFlipController.forward().then((_) {
      _pageFlipController.reverse();
    });
  }

  void _performSearch(String query, EnhancedRevelationProvider provider) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final results = <SearchResult>[];
    final timelines = provider.getCharacterTimelines();
    
    // Search through annotations
    for (final timeline in timelines.values) {
      for (final annotation in timeline.timeline) {
        if (provider.isAnnotationVisible(annotation) &&
            (annotation.text.toLowerCase().contains(query.toLowerCase()) ||
             annotation.character.toLowerCase().contains(query.toLowerCase()))) {
          results.add(SearchResult(
            type: SearchResultType.annotation,
            title: '${annotation.character} - ${annotation.year ?? "Unknown"}',
            preview: annotation.text,
            pageNumber: annotation.pageNumber,
            characterCode: annotation.character,
          ));
        }
      }
    }
    
    // Search through characters
    for (final character in provider.characters.values) {
      if (character.fullName.toLowerCase().contains(query.toLowerCase()) ||
          character.description.toLowerCase().contains(query.toLowerCase())) {
        results.add(SearchResult(
          type: SearchResultType.character,
          title: character.fullName,
          preview: character.description,
          pageNumber: 1, // Would link to first appearance
          characterCode: character.name,
        ));
      }
    }
    
    setState(() {
      _searchResults = results.take(10).toList(); // Limit results
    });
  }

  Color _getResultTypeColor(SearchResultType type) {
    switch (type) {
      case SearchResultType.annotation:
        return Colors.blue;
      case SearchResultType.character:
        return Colors.green;
      case SearchResultType.content:
        return Colors.orange;
    }
  }

  IconData _getResultTypeIcon(SearchResultType type) {
    switch (type) {
      case SearchResultType.annotation:
        return Icons.edit_note;
      case SearchResultType.character:
        return Icons.person;
      case SearchResultType.content:
        return Icons.article;
    }
  }

  void _showAnalytics(EnhancedRevelationProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AdvancedAnalyticsDialog(provider: provider),
    );
  }

  void _showCharacterTimeline(EnhancedRevelationProvider provider) {
    Navigator.of(context).pushNamed('/character_timeline');
  }

  void _showExportOptions(EnhancedRevelationProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ExportOptionsSheet(provider: provider),
    );
  }
}

// Data models for search
enum SearchResultType { annotation, character, content }

class SearchResult {
  final SearchResultType type;
  final String title;
  final String preview;
  final int pageNumber;
  final String characterCode;

  SearchResult({
    required this.type,
    required this.title,
    required this.preview,
    required this.pageNumber,
    required this.characterCode,
  });
}

// Particle system data models
class Particle {
  double x, y;
  final double size;
  final double speed;
  final double opacity;
  final Color color;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.color,
  });
}

class CandleFlame {
  final double x, y;
  final double intensity;

  CandleFlame({
    required this.x,
    required this.y,
    required this.intensity,
  });
}

// Custom painters for advanced effects
class AdvancedBackgroundPainter extends CustomPainter {
  final List<Particle> particles;
  final List<CandleFlame> candles;
  final bool supernaturalMode;
  final bool darkMode;
  final double animationValue;
  final double candlelightValue;

  AdvancedBackgroundPainter({
    required this.particles,
    required this.candles,
    required this.supernaturalMode,
    required this.darkMode,
    required this.animationValue,
    required this.candlelightValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dark mode background
    if (darkMode) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.black,
      );
    }

    // Particle effects
    for (final particle in particles) {
      _updateParticle(particle, size);
      _paintParticle(canvas, particle, size);
    }
  }

  void _updateParticle(Particle particle, Size size) {
    particle.y -= particle.speed;
    if (particle.y < 0) {
      particle.y = 1.0;
      particle.x = math.Random().nextDouble();
    }
  }

  void _paintParticle(Canvas canvas, Particle particle, Size size) {
    final paint = Paint()
      ..color = particle.color.withOpacity(particle.opacity)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(particle.x * size.width, particle.y * size.height),
      particle.size,
      paint,
    );
  }

  @override
  bool shouldRepaint(AdvancedBackgroundPainter oldDelegate) => true;
}

class SupernaturalEffectsPainter extends CustomPainter {
  final double animationValue;

  SupernaturalEffectsPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // Supernatural aura effect
    final paint = Paint()
      ..color = Colors.purple.withOpacity(0.1 * animationValue)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.3 * (1 + animationValue * 0.1),
      paint,
    );

    // Energy wisps
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) + (animationValue * 2 * math.pi);
      final x = size.width * 0.5 + math.cos(angle) * size.width * 0.2;
      final y = size.height * 0.5 + math.sin(angle) * size.height * 0.2;

      canvas.drawCircle(
        Offset(x, y),
        5 * animationValue,
        Paint()
          ..color = Colors.purple.withOpacity(0.3 * animationValue)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(SupernaturalEffectsPainter oldDelegate) => true;
}

class CandlelightPainter extends CustomPainter {
  final List<CandleFlame> candles;
  final double flickerValue;

  CandlelightPainter({
    required this.candles,
    required this.flickerValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final candle in candles) {
      final x = candle.x * size.width;
      final y = candle.y * size.height;
      final intensity = candle.intensity * flickerValue;

      // Candlelight glow
      final gradient = RadialGradient(
        colors: [
          Colors.orange.withOpacity(0.3 * intensity),
          Colors.yellow.withOpacity(0.1 * intensity),
          Colors.transparent,
        ],
      );

      canvas.drawCircle(
        Offset(x, y),
        100 * intensity,
        Paint()..shader = gradient.createShader(
          Rect.fromCircle(center: Offset(x, y), radius: 100 * intensity),
        ),
      );

      // Flame
      canvas.drawCircle(
        Offset(x, y),
        8 * intensity,
        Paint()..color = Colors.orange.withOpacity(0.8),
      );
    }
  }

  @override
  bool shouldRepaint(CandlelightPainter oldDelegate) => true;
}

// Analytics dialog
class AdvancedAnalyticsDialog extends StatelessWidget {
  final EnhancedRevelationProvider provider;

  const AdvancedAnalyticsDialog({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final stats = provider.getDiscoveryStatistics();
    
    return AlertDialog(
      title: const Text('Reading Analytics'),
      content: Container(
        width: 300,
        height: 400,
        child: Column(
          children: [
            _buildStatRow('Discovery Progress', '${stats['characterPercentage']}%'),
            _buildStatRow('Annotations Unlocked', stats['annotationProgress']),
            _buildStatRow('Current Revelation', 'Level ${stats['currentLevel']}'),
            _buildStatRow('Revealed Secrets', '${stats['revealedRedactions']}'),
            const SizedBox(height: 16),
            const Text('Next Unlock:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(stats['nextUnlock']),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// Export options sheet
class ExportOptionsSheet extends StatelessWidget {
  final EnhancedRevelationProvider provider;

  const ExportOptionsSheet({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Export Options',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          ListTile(
            leading: const Icon(Icons.timeline),
            title: const Text('Character Timeline'),
            subtitle: const Text('Export complete timeline as PDF'),
            onTap: () => _exportTimeline(context),
          ),
          
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Discovery Report'),
            subtitle: const Text('Generate reading progress report'),
            onTap: () => _exportReport(context),
          ),
          
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Character Profiles'),
            subtitle: const Text('Export all discovered character data'),
            onTap: () => _exportProfiles(context),
          ),
        ],
      ),
    );
  }

  void _exportTimeline(BuildContext context) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Timeline export started...')),
    );
  }

  void _exportReport(BuildContext context) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report export started...')),
    );
  }

  void _exportProfiles(BuildContext context) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Character profiles export started...')),
    );
  }
}