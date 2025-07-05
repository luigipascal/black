import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import '../../services/reading_experience_service.dart';

class ReadingGoalsAchievementsWidget extends StatefulWidget {
  const ReadingGoalsAchievementsWidget({super.key});

  @override
  State<ReadingGoalsAchievementsWidget> createState() => _ReadingGoalsAchievementsWidgetState();
}

class _ReadingGoalsAchievementsWidgetState extends State<ReadingGoalsAchievementsWidget>
    with TickerProviderStateMixin {
  final ReadingExperienceService _readingService = ReadingExperienceService();
  
  late AnimationController _headerController;
  late AnimationController _achievementController;
  late AnimationController _goalsController;
  
  late Animation<double> _headerAnimation;
  late Animation<double> _achievementAnimation;
  late Animation<double> _goalsAnimation;
  
  int _selectedTab = 0;
  bool _isLoading = true;
  
  final List<String> _tabs = ['Goals', 'Achievements', 'Statistics'];

  @override
  void initState() {
    super.initState();
    
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _achievementController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _goalsController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack),
    );
    
    _achievementAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _achievementController, curve: Curves.elasticOut),
    );
    
    _goalsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _goalsController, curve: Curves.easeInOut),
    );
    
    _initializeWidget();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _achievementController.dispose();
    _goalsController.dispose();
    super.dispose();
  }

  Future<void> _initializeWidget() async {
    await _readingService.initialize();
    
    setState(() {
      _isLoading = false;
    });
    
    _startAnimations();
  }

  void _startAnimations() {
    _headerController.forward();
    
    Future.delayed(const Duration(milliseconds: 200), () {
      _goalsController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 400), () {
      _achievementController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    return Column(
      children: [
        // Animated header
        _buildAnimatedHeader(),
        
        // Tab selector
        _buildTabSelector(),
        
        // Tab content
        Expanded(child: _buildTabContent()),
      ],
    );
  }

  Widget _buildAnimatedHeader() {
    final statistics = _readingService.getStatistics();
    
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (_headerAnimation.value * 0.2),
          child: Opacity(
            opacity: _headerAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple[400]!,
                    Colors.blue[500]!,
                    Colors.teal[400]!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: Colors.white,
                        size: 32 * _headerAnimation.value,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Reading Journey',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Quick stats
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickStat(
                          Icons.book,
                          '${statistics.totalPagesRead}',
                          'Pages Read',
                        ),
                      ),
                      Expanded(
                        child: _buildQuickStat(
                          Icons.local_fire_department,
                          '${statistics.currentStreak}',
                          'Day Streak',
                        ),
                      ),
                      Expanded(
                        child: _buildQuickStat(
                          Icons.access_time,
                          '${statistics.totalReadingTime.inHours}h',
                          'Total Time',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[500] : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildGoalsTab();
      case 1:
        return _buildAchievementsTab();
      case 2:
        return _buildStatisticsTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildGoalsTab() {
    final goals = _readingService.getGoals();
    
    return AnimatedBuilder(
      animation: _goalsAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _goalsAnimation.value)),
          child: Opacity(
            opacity: _goalsAnimation.value,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Add custom goal button
                _buildAddGoalButton(),
                
                const SizedBox(height: 16),
                
                // Active goals
                Text(
                  'Active Goals',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                ...goals.where((goal) => !goal.isCompleted).map((goal) => 
                    _buildGoalCard(goal, false)),
                
                const SizedBox(height: 24),
                
                // Completed goals
                if (goals.any((goal) => goal.isCompleted)) ...[
                  Text(
                    'Completed Goals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  ...goals.where((goal) => goal.isCompleted).map((goal) => 
                      _buildGoalCard(goal, true)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddGoalButton() {
    return GestureDetector(
      onTap: () => _showAddGoalDialog(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[200]!, width: 2, style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Icon(Icons.add_circle_outline, color: Colors.blue[600], size: 24),
            const SizedBox(width: 12),
            Text(
              'Add Custom Goal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue[600],
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: Colors.blue[600], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(ReadingGoal goal, bool isCompleted) {
    final progress = _calculateGoalProgress(goal);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.green[200]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Icon(
                isCompleted ? Icons.check_circle : _getGoalIcon(goal.type),
                color: isCompleted ? Colors.green[600] : Colors.blue[600],
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  goal.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.green[800] : Colors.grey[800],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getGoalPeriodColor(goal.period).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  goal.period.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getGoalPeriodColor(goal.period),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            goal.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Progress bar
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(
                    isCompleted ? Colors.green[400]! : Colors.blue[400]!,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? Colors.green[600] : Colors.blue[600],
                ),
              ),
            ],
          ),
          
          if (isCompleted && goal.completedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Completed ${_formatDate(goal.completedAt!)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAchievementsTab() {
    final achievements = _readingService.getAchievements();
    final unlockedAchievements = _readingService.getUnlockedAchievements();
    
    return AnimatedBuilder(
      animation: _achievementAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + (_achievementAnimation.value * 0.1),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Achievement progress
              _buildAchievementProgress(achievements, unlockedAchievements),
              
              const SizedBox(height: 24),
              
              // Unlocked achievements
              Text(
                'Unlocked Achievements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              
              const SizedBox(height: 12),
              
              ...achievements.where((achievement) => 
                  unlockedAchievements.contains(achievement.id)).map((achievement) => 
                  _buildAchievementCard(achievement, true)),
              
              const SizedBox(height: 24),
              
              // Locked achievements
              Text(
                'Locked Achievements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              
              const SizedBox(height: 12),
              
              ...achievements.where((achievement) => 
                  !unlockedAchievements.contains(achievement.id)).map((achievement) => 
                  _buildAchievementCard(achievement, false)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievementProgress(List<ReadingAchievement> achievements, Set<String> unlocked) {
    final progress = unlocked.length / achievements.length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber[400]!, Colors.orange[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Achievement Progress',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  minHeight: 8,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${unlocked.length}/${achievements.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(ReadingAchievement achievement, bool isUnlocked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUnlocked ? Colors.white : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isUnlocked ? _getRarityColor(achievement.rarity) : Colors.grey[300]!,
                width: 2,
              ),
              boxShadow: isUnlocked ? [
                BoxShadow(
                  color: _getRarityColor(achievement.rarity).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ] : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isUnlocked ? _getRarityColor(achievement.rarity) : Colors.grey[400],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getAchievementIcon(achievement.condition.type),
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? Colors.black : Colors.grey[600],
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        achievement.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isUnlocked ? Colors.grey[600] : Colors.grey[500],
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getRarityColor(achievement.rarity).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              achievement.rarity.toString().split('.').last.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getRarityColor(achievement.rarity),
                              ),
                            ),
                          ),
                          
                          if (isUnlocked && achievement.unlockedAt != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Unlocked ${_formatDate(achievement.unlockedAt!)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (!isUnlocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    final statistics = _readingService.getStatistics();
    final recommendations = _readingService.getRecommendations();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Reading statistics
        _buildStatisticsSection('Reading Statistics', [
          StatItem('Total Reading Time', '${statistics.totalReadingTime.inHours}h ${statistics.totalReadingTime.inMinutes % 60}m'),
          StatItem('Pages Read', '${statistics.totalPagesRead} / 247'),
          StatItem('Words Read', '${statistics.totalWordsRead}'),
          StatItem('Average Session', '${statistics.averageSessionDuration.inMinutes}m'),
          StatItem('Reading Speed', '${statistics.averageReadingSpeed.toInt()} words/min'),
          StatItem('Current Streak', '${statistics.currentStreak} days'),
          StatItem('Longest Streak', '${statistics.longestStreak} days'),
        ]),
        
        const SizedBox(height: 24),
        
        // Recommendations
        if (recommendations.isNotEmpty)
          _buildRecommendationsSection(recommendations),
      ],
    );
  }

  Widget _buildStatisticsSection(String title, List<StatItem> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: stats.asMap().entries.map((entry) {
              final index = entry.key;
              final stat = entry.value;
              
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        stat.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        stat.value,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                  
                  if (index < stats.length - 1) ...[
                    const SizedBox(height: 12),
                    Divider(color: Colors.grey[200], height: 1),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsSection(List<ReadingRecommendation> recommendations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommendations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        
        const SizedBox(height: 12),
        
        ...recommendations.map((recommendation) => _buildRecommendationCard(recommendation)),
      ],
    );
  }

  Widget _buildRecommendationCard(ReadingRecommendation recommendation) {
    final priorityColor = _getPriorityColor(recommendation.priority);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: priorityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: priorityColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _getRecommendationIcon(recommendation.type),
            color: priorityColor,
            size: 24,
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: priorityColor,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  recommendation.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  double _calculateGoalProgress(ReadingGoal goal) {
    final statistics = _readingService.getStatistics();
    
    switch (goal.type) {
      case GoalType.readingTime:
        return statistics.totalReadingTime.inMinutes / goal.target;
      case GoalType.pagesRead:
        return statistics.totalPagesRead / goal.target;
      case GoalType.completion:
        return (statistics.totalPagesRead / 247.0) / (goal.target / 100.0);
    }
  }

  IconData _getGoalIcon(GoalType type) {
    switch (type) {
      case GoalType.readingTime:
        return Icons.access_time;
      case GoalType.pagesRead:
        return Icons.book;
      case GoalType.completion:
        return Icons.check_circle;
    }
  }

  Color _getGoalPeriodColor(GoalPeriod period) {
    switch (period) {
      case GoalPeriod.daily:
        return Colors.green;
      case GoalPeriod.weekly:
        return Colors.blue;
      case GoalPeriod.monthly:
        return Colors.purple;
    }
  }

  IconData _getAchievementIcon(AchievementType type) {
    switch (type) {
      case AchievementType.pagesRead:
        return Icons.menu_book;
      case AchievementType.readingTime:
        return Icons.schedule;
      case AchievementType.readingStreak:
        return Icons.local_fire_department;
      case AchievementType.readingSpeed:
        return Icons.speed;
      case AchievementType.completion:
        return Icons.emoji_events;
    }
  }

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.amber;
    }
  }

  IconData _getRecommendationIcon(RecommendationType type) {
    switch (type) {
      case RecommendationType.sessionLength:
        return Icons.timer;
      case RecommendationType.readingSpeed:
        return Icons.speed;
      case RecommendationType.readingMode:
        return Icons.brightness_6;
      case RecommendationType.content:
        return Icons.explore;
    }
  }

  Color _getPriorityColor(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.low:
        return Colors.green;
      case RecommendationPriority.medium:
        return Colors.orange;
      case RecommendationPriority.high:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showAddGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => AddGoalDialog(
        onGoalAdded: (goal) {
          _readingService.addGoal(goal);
          setState(() {});
        },
      ),
    );
  }
}

// Custom dialog for adding goals
class AddGoalDialog extends StatefulWidget {
  final Function(ReadingGoal) onGoalAdded;

  const AddGoalDialog({super.key, required this.onGoalAdded});

  @override
  State<AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<AddGoalDialog> {
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  GoalType _selectedType = GoalType.pagesRead;
  GoalPeriod _selectedPeriod = GoalPeriod.daily;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Custom Goal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Goal Title',
              hintText: 'e.g., Read 10 pages',
            ),
          ),
          
          const SizedBox(height: 16),
          
          TextField(
            controller: _targetController,
            decoration: const InputDecoration(
              labelText: 'Target',
              hintText: 'e.g., 10',
            ),
            keyboardType: TextInputType.number,
          ),
          
          const SizedBox(height: 16),
          
          DropdownButtonFormField<GoalType>(
            value: _selectedType,
            decoration: const InputDecoration(labelText: 'Goal Type'),
            items: GoalType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.toString().split('.').last),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          DropdownButtonFormField<GoalPeriod>(
            value: _selectedPeriod,
            decoration: const InputDecoration(labelText: 'Period'),
            items: GoalPeriod.values.map((period) {
              return DropdownMenuItem(
                value: period,
                child: Text(period.toString().split('.').last),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedPeriod = value!;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty && _targetController.text.isNotEmpty) {
              final goal = ReadingGoal(
                id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                title: _titleController.text,
                description: 'Custom goal: ${_titleController.text}',
                target: int.parse(_targetController.text),
                type: _selectedType,
                period: _selectedPeriod,
              );
              
              widget.onGoalAdded(goal);
              Navigator.pop(context);
            }
          },
          child: const Text('Add Goal'),
        ),
      ],
    );
  }
}

// Helper class for statistics
class StatItem {
  final String label;
  final String value;

  StatItem(this.label, this.value);
}