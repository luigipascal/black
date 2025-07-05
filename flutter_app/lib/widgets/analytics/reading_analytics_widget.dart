import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../../services/advanced_search_service.dart';
import '../../models/enhanced_document_models.dart';
import '../../providers/enhanced_revelation_provider.dart';

class ReadingAnalyticsWidget extends StatefulWidget {
  const ReadingAnalyticsWidget({super.key});

  @override
  State<ReadingAnalyticsWidget> createState() => _ReadingAnalyticsWidgetState();
}

class _ReadingAnalyticsWidgetState extends State<ReadingAnalyticsWidget>
    with TickerProviderStateMixin {
  final AdvancedSearchService _searchService = AdvancedSearchService();
  
  late AnimationController _progressController;
  late AnimationController _chartController;
  late AnimationController _insightsController;
  
  late Animation<double> _progressAnimation;
  late Animation<double> _chartAnimation;
  late Animation<double> _insightsAnimation;
  
  int _selectedTab = 0;
  Map<String, dynamic> _analytics = {};
  
  final List<AnalyticsTab> _tabs = [
    AnalyticsTab(title: 'Progress', icon: Icons.trending_up),
    AnalyticsTab(title: 'Time', icon: Icons.schedule),
    AnalyticsTab(title: 'Discovery', icon: Icons.explore),
    AnalyticsTab(title: 'Insights', icon: Icons.lightbulb),
  ];

  @override
  void initState() {
    super.initState();
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _insightsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    _chartAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _chartController,
      curve: Curves.elasticOut,
    ));
    
    _insightsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _insightsController,
      curve: Curves.easeInOut,
    ));
    
    _loadAnalytics();
    _startAnimations();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _chartController.dispose();
    _insightsController.dispose();
    super.dispose();
  }

  void _loadAnalytics() {
    final readingProgress = _searchService.getReadingProgress();
    final totalReadingTime = _searchService.getTotalReadingTime();
    final pageReadingTimes = _searchService.getPageReadingTimes();
    final searchStats = _searchService.getSearchStats();
    
    setState(() {
      _analytics = {
        'readingProgress': readingProgress,
        'totalReadingTime': totalReadingTime,
        'pageReadingTimes': pageReadingTimes,
        'searchStats': searchStats,
        'averagePageTime': _calculateAveragePageTime(pageReadingTimes),
        'readingStreak': _calculateReadingStreak(),
        'favoriteSearchTerms': _getFavoriteSearchTerms(searchStats),
        'readingVelocity': _calculateReadingVelocity(pageReadingTimes),
      };
    });
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _progressController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 300), () {
      _chartController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 500), () {
      _insightsController.forward();
    });
  }

  Duration _calculateAveragePageTime(Map<int, Duration> pageReadingTimes) {
    if (pageReadingTimes.isEmpty) return Duration.zero;
    
    final totalSeconds = pageReadingTimes.values
        .map((duration) => duration.inSeconds)
        .reduce((a, b) => a + b);
    
    return Duration(seconds: totalSeconds ~/ pageReadingTimes.length);
  }

  int _calculateReadingStreak() {
    // Simplified streak calculation - in real app would check daily reading
    return math.Random().nextInt(15) + 1;
  }

  List<MapEntry<String, int>> _getFavoriteSearchTerms(Map<String, int> searchStats) {
    final entries = searchStats.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }

  double _calculateReadingVelocity(Map<int, Duration> pageReadingTimes) {
    if (pageReadingTimes.isEmpty) return 0.0;
    
    // Pages per hour
    final totalHours = pageReadingTimes.values
        .map((duration) => duration.inMinutes)
        .reduce((a, b) => a + b) / 60.0;
    
    return totalHours > 0 ? pageReadingTimes.length / totalHours : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedRevelationProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Header
            _buildHeader(),
            
            // Tab selector
            _buildTabSelector(),
            
            // Content
            Expanded(child: _buildTabContent(provider)),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[400]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: const Text(
              'Reading Analytics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          
          // Export button
          IconButton(
            icon: const Icon(Icons.file_download, color: Colors.white),
            onPressed: () => _exportAnalytics(),
          ),
          
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _loadAnalytics();
              _startAnimations();
              HapticFeedback.lightImpact();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: _tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = index == _selectedTab;
          
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = index;
                });
                HapticFeedback.lightImpact();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[500] : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.blue[500]! : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tab.icon,
                      color: isSelected ? Colors.white : Colors.grey[600],
                      size: 18,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tab.title,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent(EnhancedRevelationProvider provider) {
    switch (_selectedTab) {
      case 0:
        return _buildProgressTab(provider);
      case 1:
        return _buildTimeTab(provider);
      case 2:
        return _buildDiscoveryTab(provider);
      case 3:
        return _buildInsightsTab(provider);
      default:
        return const SizedBox();
    }
  }

  Widget _buildProgressTab(EnhancedRevelationProvider provider) {
    final progress = _analytics['readingProgress'] ?? 0.0;
    
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Overall progress circle
              _buildProgressCircle(progress, 'Overall Progress'),
              
              const SizedBox(height: 24),
              
              // Section progress
              _buildSectionProgress(provider),
              
              const SizedBox(height: 24),
              
              // Reading milestones
              _buildReadingMilestones(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressCircle(double progress, String title) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              children: [
                // Background circle
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(Colors.grey[200]!),
                  ),
                ),
                
                // Progress circle
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: progress * _progressAnimation.value,
                    strokeWidth: 8,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation(Colors.blue[500]!),
                  ),
                ),
                
                // Center text
                Center(
                  child: Text(
                    '${(progress * _progressAnimation.value * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionProgress(EnhancedRevelationProvider provider) {
    final sections = [
      SectionProgress(name: 'Front Matter', progress: 0.8, color: Colors.blue),
      SectionProgress(name: 'Main Content', progress: 0.6, color: Colors.green),
      SectionProgress(name: 'Appendices', progress: 0.3, color: Colors.orange),
    ];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Section Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          ...sections.map((section) => _buildSectionProgressBar(section)),
        ],
      ),
    );
  }

  Widget _buildSectionProgressBar(SectionProgress section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                section.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${(section.progress * 100).toInt()}%',
                style: TextStyle(
                  color: section.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          LinearProgressIndicator(
            value: section.progress * _progressAnimation.value,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(section.color),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildReadingMilestones() {
    final milestones = [
      ReadingMilestone(
        title: 'First Page Read',
        description: 'Started your investigation',
        achieved: true,
        icon: Icons.play_arrow,
      ),
      ReadingMilestone(
        title: 'Character Discovery',
        description: 'Found your first character clue',
        achieved: true,
        icon: Icons.person_search,
      ),
      ReadingMilestone(
        title: 'Mystery Solver',
        description: 'Uncovered 50% of the content',
        achieved: false,
        icon: Icons.psychology,
      ),
      ReadingMilestone(
        title: 'Truth Seeker',
        description: 'Reached maximum revelation level',
        achieved: false,
        icon: Icons.visibility,
      ),
    ];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reading Milestones',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          ...milestones.map((milestone) => _buildMilestoneItem(milestone)),
        ],
      ),
    );
  }

  Widget _buildMilestoneItem(ReadingMilestone milestone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: milestone.achieved ? Colors.green : Colors.grey[300],
            child: Icon(
              milestone.achieved ? Icons.check : milestone.icon,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: milestone.achieved ? Colors.black : Colors.grey[600],
                  ),
                ),
                Text(
                  milestone.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          if (milestone.achieved)
            Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  Widget _buildTimeTab(EnhancedRevelationProvider provider) {
    final totalTime = _analytics['totalReadingTime'] ?? Duration.zero;
    final averageTime = _analytics['averagePageTime'] ?? Duration.zero;
    final readingVelocity = _analytics['readingVelocity'] ?? 0.0;
    
    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Time summary cards
              Row(
                children: [
                  Expanded(
                    child: _buildTimeCard(
                      'Total Time',
                      '${totalTime.inHours}h ${totalTime.inMinutes % 60}m',
                      Icons.schedule,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTimeCard(
                      'Avg/Page',
                      '${averageTime.inMinutes}m',
                      Icons.timer,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildTimeCard(
                      'Reading Speed',
                      '${readingVelocity.toStringAsFixed(1)} p/h',
                      Icons.speed,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTimeCard(
                      'Streak',
                      '${_analytics['readingStreak']} days',
                      Icons.local_fire_department,
                      Colors.red,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Reading time chart
              _buildReadingTimeChart(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeCard(String title, String value, IconData icon, Color color) {
    return Transform.scale(
      scale: _chartAnimation.value,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingTimeChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reading Time Distribution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: CustomPaint(
              painter: ReadingTimeChartPainter(
                animationValue: _chartAnimation.value,
              ),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryTab(EnhancedRevelationProvider provider) {
    final stats = provider.getDiscoveryStatistics();
    
    return AnimatedBuilder(
      animation: _insightsAnimation,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Discovery progress
              _buildDiscoveryProgress(stats),
              
              const SizedBox(height: 24),
              
              // Character discovery
              _buildCharacterDiscovery(provider),
              
              const SizedBox(height: 24),
              
              // Search activity
              _buildSearchActivity(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDiscoveryProgress(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Discovery Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildStatRow('Characters Found', '${stats['charactersDiscovered']}/6'),
          _buildStatRow('Annotations Unlocked', stats['annotationProgress']),
          _buildStatRow('Revelation Level', 'Level ${stats['currentLevel']}'),
          _buildStatRow('Secrets Revealed', '${stats['revealedRedactions']}'),
        ],
      ),
    );
  }

  Widget _buildCharacterDiscovery(EnhancedRevelationProvider provider) {
    final characters = provider.getDiscoveredCharacters();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Discovered Characters',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          ...characters.map((character) => _buildCharacterItem(character)),
        ],
      ),
    );
  }

  Widget _buildCharacterItem(Character character) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: character.primaryColor,
            child: Text(
              character.name.substring(0, 2),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Text(
              character.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          
          if (character.isMissing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'MISSING',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchActivity() {
    final favoriteTerms = _analytics['favoriteSearchTerms'] ?? <MapEntry<String, int>>[];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search Activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (favoriteTerms.isEmpty)
            const Text('No search activity yet')
          else
            ...favoriteTerms.map((entry) => _buildSearchTermItem(entry)),
        ],
      ),
    );
  }

  Widget _buildSearchTermItem(MapEntry<String, int> entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              entry.key,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${entry.value}x',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab(EnhancedRevelationProvider provider) {
    return AnimatedBuilder(
      animation: _insightsAnimation,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildReadingInsights(),
              const SizedBox(height: 24),
              _buildRecommendations(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReadingInsights() {
    final insights = [
      'You tend to read longer on weekends',
      'Mystery sections hold your attention longer',
      'You\'re most active during evening hours',
      'Character discovery drives your engagement',
    ];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber[600], size: 24),
              const SizedBox(width: 8),
              const Text(
                'Reading Insights',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ...insights.map((insight) => _buildInsightItem(insight)),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String insight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Colors.amber[600],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insight,
              style: const TextStyle(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = [
      'Try searching for "supernatural" to unlock hidden content',
      'Visit Appendix F for missing persons clues',
      'Character timelines reveal important connections',
      'Bookmark important pages for quick reference',
    ];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.recommend, color: Colors.green[600], size: 24),
              const SizedBox(width: 8),
              const Text(
                'Recommendations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ...recommendations.map((recommendation) => _buildRecommendationItem(recommendation)),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String recommendation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.green[600],
            size: 12,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              recommendation,
              style: const TextStyle(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _exportAnalytics() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Export Analytics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              ListTile(
                leading: const Icon(Icons.file_download),
                title: const Text('Export as PDF'),
                onTap: () => Navigator.pop(context),
              ),
              
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share Summary'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Data models
class AnalyticsTab {
  final String title;
  final IconData icon;

  AnalyticsTab({required this.title, required this.icon});
}

class SectionProgress {
  final String name;
  final double progress;
  final Color color;

  SectionProgress({
    required this.name,
    required this.progress,
    required this.color,
  });
}

class ReadingMilestone {
  final String title;
  final String description;
  final bool achieved;
  final IconData icon;

  ReadingMilestone({
    required this.title,
    required this.description,
    required this.achieved,
    required this.icon,
  });
}

// Custom painter for reading time chart
class ReadingTimeChartPainter extends CustomPainter {
  final double animationValue;

  ReadingTimeChartPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue[300]!
      ..style = PaintingStyle.fill;

    // Simple bar chart simulation
    final barWidth = size.width / 7;
    final heights = [0.3, 0.7, 0.5, 0.9, 0.6, 0.8, 0.4];

    for (int i = 0; i < heights.length; i++) {
      final height = size.height * heights[i] * animationValue;
      final x = i * barWidth;
      final y = size.height - height;

      canvas.drawRect(
        Rect.fromLTWH(x, y, barWidth * 0.8, height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ReadingTimeChartPainter oldDelegate) => true;
}