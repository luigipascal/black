import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

import '../../providers/enhanced_revelation_provider.dart';
import '../../models/enhanced_document_models.dart';
import '../../services/reading_experience_service.dart';

class ReadingAnalyticsWidget extends StatefulWidget {
  final int currentPageIndex;
  final int totalPages;
  final Duration sessionDuration;
  final List<EnhancedAnnotation> viewedAnnotations;
  
  const ReadingAnalyticsWidget({
    super.key,
    required this.currentPageIndex,
    required this.totalPages,
    required this.sessionDuration,
    required this.viewedAnnotations,
  });

  @override
  State<ReadingAnalyticsWidget> createState() => _ReadingAnalyticsWidgetState();
}

class _ReadingAnalyticsWidgetState extends State<ReadingAnalyticsWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    _progressController.forward();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedRevelationProvider>(
      builder: (context, provider, child) {
        final readingService = ReadingExperienceService();
        final analytics = readingService.getReadingAnalytics(
          provider.userProgress,
          widget.currentPageIndex,
          widget.totalPages,
        );
        
        return Container(
          height: 600,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with statistics
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade50,
                      Colors.purple.shade50,
                    ],
                  ),
                ),
                child: _buildStatisticsHeader(analytics),
              ),
              
              // Tab bar
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue,
                  tabs: const [
                    Tab(text: 'Progress', icon: Icon(Icons.track_changes)),
                    Tab(text: 'Time', icon: Icon(Icons.access_time)),
                    Tab(text: 'Discovery', icon: Icon(Icons.explore)),
                    Tab(text: 'Insights', icon: Icon(Icons.lightbulb)),
                  ],
                ),
              ),
              
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProgressTab(analytics),
                    _buildTimeTab(analytics),
                    _buildDiscoveryTab(analytics, provider),
                    _buildInsightsTab(analytics, provider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildStatisticsHeader(Map<String, dynamic> analytics) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatCard(
          'Progress',
          '${analytics['progressPercentage']?.toStringAsFixed(1) ?? '0.0'}%',
          Icons.trending_up,
          Colors.blue,
        ),
        _buildStatCard(
          'Time',
          _formatDuration(analytics['totalReadingTime'] ?? Duration.zero),
          Icons.schedule,
          Colors.green,
        ),
        _buildStatCard(
          'Characters',
          '${analytics['charactersDiscovered'] ?? 0}/6',
          Icons.people,
          Colors.purple,
        ),
        _buildStatCard(
          'Level',
          '${analytics['revelationLevel'] ?? 1}/5',
          Icons.star,
          Colors.orange,
        ),
      ],
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * _progressAnimation.value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildProgressTab(Map<String, dynamic> analytics) {
    final progress = analytics['progressPercentage'] ?? 0.0;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Circular progress indicator
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return CircularProgressIndicator(
                        value: (progress / 100) * _progressAnimation.value,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color.lerp(Colors.blue, Colors.purple, progress / 100) ?? Colors.blue,
                        ),
                      );
                    },
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return Text(
                          '${(progress * _progressAnimation.value).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    const Text(
                      'Complete',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Section breakdown
          _buildSectionBreakdown(analytics),
          
          const SizedBox(height: 20),
          
          // Reading milestones
          _buildReadingMilestones(analytics),
        ],
      ),
    );
  }
  
  Widget _buildSectionBreakdown(Map<String, dynamic> analytics) {
    final sections = [
      {'name': 'Front Matter', 'progress': analytics['frontMatterProgress'] ?? 0.0, 'color': Colors.blue},
      {'name': 'Main Content', 'progress': analytics['mainContentProgress'] ?? 0.0, 'color': Colors.green},
      {'name': 'Appendices', 'progress': analytics['appendicesProgress'] ?? 0.0, 'color': Colors.purple},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Section Progress',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...sections.map((section) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(section['name'] as String),
                  Text('${(section['progress'] as double).toStringAsFixed(1)}%'),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: (section['progress'] as double) / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(section['color'] as Color),
              ),
            ],
          ),
        )),
      ],
    );
  }
  
  Widget _buildReadingMilestones(Map<String, dynamic> analytics) {
    final milestones = [
      {'title': 'First Page', 'completed': true, 'icon': Icons.flag},
      {'title': 'Character Discovery', 'completed': (analytics['charactersDiscovered'] ?? 0) > 0, 'icon': Icons.people},
      {'title': 'Halfway Point', 'completed': (analytics['progressPercentage'] ?? 0) >= 50, 'icon': Icons.trending_up},
      {'title': 'All Characters', 'completed': (analytics['charactersDiscovered'] ?? 0) >= 6, 'icon': Icons.group},
      {'title': 'Complete Truth', 'completed': (analytics['revelationLevel'] ?? 1) >= 5, 'icon': Icons.star},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reading Milestones',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: milestones.map((milestone) {
            final completed = milestone['completed'] as bool;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: completed ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: completed ? Colors.green : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    milestone['icon'] as IconData,
                    size: 16,
                    color: completed ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    milestone['title'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: completed ? Colors.green : Colors.grey,
                      fontWeight: completed ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildTimeTab(Map<String, dynamic> analytics) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Time statistics cards
          Row(
            children: [
              Expanded(
                child: _buildTimeCard(
                  'Total Time',
                  _formatDuration(analytics['totalReadingTime'] ?? Duration.zero),
                  Icons.schedule,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeCard(
                  'Avg/Page',
                  _formatDuration(analytics['averageTimePerPage'] ?? Duration.zero),
                  Icons.timer,
                  Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildTimeCard(
                  'Speed',
                  '${analytics['pagesPerHour']?.toStringAsFixed(1) ?? '0.0'} p/h',
                  Icons.speed,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeCard(
                  'Streak',
                  '${analytics['readingStreak'] ?? 0} days',
                  Icons.local_fire_department,
                  Colors.red,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Reading time chart
          _buildReadingTimeChart(analytics),
        ],
      ),
    );
  }
  
  Widget _buildTimeCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReadingTimeChart(Map<String, dynamic> analytics) {
    final readingHistory = analytics['readingHistory'] as List<Map<String, dynamic>>? ?? [];
    
    if (readingHistory.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text(
          'No reading history available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    
    return Container(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: readingHistory.asMap().entries.map((entry) {
                return FlSpot(
                  entry.key.toDouble(),
                  (entry.value['minutes'] as double? ?? 0.0),
                );
              }).toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDiscoveryTab(Map<String, dynamic> analytics, EnhancedRevelationProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Discovery progress
          _buildDiscoveryProgress(analytics, provider),
          
          const SizedBox(height: 20),
          
          // Character discovery grid
          _buildCharacterDiscoveryGrid(provider),
          
          const SizedBox(height: 20),
          
          // Search activity
          _buildSearchActivity(analytics),
        ],
      ),
    );
  }
  
  Widget _buildDiscoveryProgress(Map<String, dynamic> analytics, EnhancedRevelationProvider provider) {
    final discoveryStats = [
      {
        'title': 'Characters',
        'current': analytics['charactersDiscovered'] ?? 0,
        'total': 6,
        'color': Colors.purple,
      },
      {
        'title': 'Annotations',
        'current': analytics['annotationsViewed'] ?? 0,
        'total': 535,
        'color': Colors.blue,
      },
      {
        'title': 'Revelation',
        'current': analytics['revelationLevel'] ?? 1,
        'total': 5,
        'color': Colors.orange,
      },
    ];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: discoveryStats.map((stat) {
        final progress = (stat['current'] as int) / (stat['total'] as int);
        return Column(
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(stat['color'] as Color),
                  ),
                  Text(
                    '${stat['current']}/${stat['total']}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              stat['title'] as String,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
  
  Widget _buildCharacterDiscoveryGrid(EnhancedRevelationProvider provider) {
    final characters = provider.characters.values.toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Character Discovery',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.0,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: characters.length,
          itemBuilder: (context, index) {
            final character = characters[index];
            return Container(
              decoration: BoxDecoration(
                color: character.isDiscovered ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: character.isDiscovered ? Colors.green : Colors.grey.shade300,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    character.isDiscovered ? Icons.check_circle : Icons.help_outline,
                    color: character.isDiscovered ? Colors.green : Colors.grey,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    character.initials,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: character.isDiscovered ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildSearchActivity(Map<String, dynamic> analytics) {
    final searchHistory = analytics['searchHistory'] as List<String>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Search Activity',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        if (searchHistory.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'No search history available',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: searchHistory.take(6).map((query) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  query,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade800,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
  
  Widget _buildInsightsTab(Map<String, dynamic> analytics, EnhancedRevelationProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Reading insights
          _buildReadingInsights(analytics),
          
          const SizedBox(height: 20),
          
          // Recommendations
          _buildRecommendations(analytics, provider),
          
          const SizedBox(height: 20),
          
          // Engagement patterns
          _buildEngagementPatterns(analytics),
        ],
      ),
    );
  }
  
  Widget _buildReadingInsights(Map<String, dynamic> analytics) {
    final insights = [
      {
        'title': 'Reading Pace',
        'description': _getReadingPaceInsight(analytics),
        'icon': Icons.speed,
        'color': Colors.blue,
      },
      {
        'title': 'Discovery Style',
        'description': _getDiscoveryStyleInsight(analytics),
        'icon': Icons.explore,
        'color': Colors.green,
      },
      {
        'title': 'Focus Areas',
        'description': _getFocusAreasInsight(analytics),
        'icon': Icons.center_focus_strong,
        'color': Colors.purple,
      },
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reading Insights',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...insights.map((insight) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (insight['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: (insight['color'] as Color).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  insight['icon'] as IconData,
                  color: insight['color'] as Color,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight['title'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        insight['description'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
  
  Widget _buildRecommendations(Map<String, dynamic> analytics, EnhancedRevelationProvider provider) {
    final recommendations = _getPersonalizedRecommendations(analytics, provider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommendations',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...recommendations.map((rec) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Colors.orange.shade600,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rec,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
  
  Widget _buildEngagementPatterns(Map<String, dynamic> analytics) {
    final patterns = [
      'Most active during evenings',
      'Prefers detailed annotation exploration',
      'High engagement with character timelines',
      'Shows strong mystery-solving focus',
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Engagement Patterns',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...patterns.map((pattern) {
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.insights,
                  color: Colors.grey.shade600,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pattern,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
  
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
  
  String _getReadingPaceInsight(Map<String, dynamic> analytics) {
    final speed = analytics['pagesPerHour'] as double? ?? 0.0;
    
    if (speed > 20) {
      return 'Fast reader - you cover content quickly';
    } else if (speed > 10) {
      return 'Moderate pace - balanced reading style';
    } else {
      return 'Thorough reader - you take time to absorb details';
    }
  }
  
  String _getDiscoveryStyleInsight(Map<String, dynamic> analytics) {
    final searchCount = analytics['searchCount'] as int? ?? 0;
    
    if (searchCount > 20) {
      return 'Active searcher - you explore content thoroughly';
    } else if (searchCount > 10) {
      return 'Balanced explorer - mix of linear and search-driven reading';
    } else {
      return 'Linear reader - you prefer following the natural flow';
    }
  }
  
  String _getFocusAreasInsight(Map<String, dynamic> analytics) {
    final annotationViews = analytics['annotationsViewed'] as int? ?? 0;
    
    if (annotationViews > 100) {
      return 'Detail-oriented - you engage deeply with annotations';
    } else if (annotationViews > 50) {
      return 'Balanced focus - moderate annotation engagement';
    } else {
      return 'Main content focused - you prefer the primary narrative';
    }
  }
  
  List<String> _getPersonalizedRecommendations(Map<String, dynamic> analytics, EnhancedRevelationProvider provider) {
    final recommendations = <String>[];
    
    final progress = analytics['progressPercentage'] as double? ?? 0.0;
    final charactersDiscovered = analytics['charactersDiscovered'] as int? ?? 0;
    final revelationLevel = analytics['revelationLevel'] as int? ?? 1;
    
    if (progress < 25) {
      recommendations.add('Continue reading to unlock more character perspectives');
    }
    
    if (charactersDiscovered < 3) {
      recommendations.add('Look for annotations to discover more investigators');
    }
    
    if (revelationLevel < 3) {
      recommendations.add('Explore different content sections to advance revelation levels');
    }
    
    if (analytics['searchCount'] as int? ?? 0 < 5) {
      recommendations.add('Try using search to find specific clues or characters');
    }
    
    if (provider.characters.values.any((c) => c.isMissing)) {
      recommendations.add('Focus on missing persons timeline for key insights');
    }
    
    return recommendations;
  }
}