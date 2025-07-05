import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enhanced_document_models.dart';
import '../providers/enhanced_revelation_provider.dart';
import '../constants/app_theme.dart';
import 'character_timeline_widget.dart';

class CharacterFocusModeWidget extends StatefulWidget {
  final String characterCode;

  const CharacterFocusModeWidget({
    super.key,
    required this.characterCode,
  });

  @override
  State<CharacterFocusModeWidget> createState() => _CharacterFocusModeWidgetState();
}

class _CharacterFocusModeWidgetState extends State<CharacterFocusModeWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _headerAnimationController;
  late Animation<double> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _headerSlideAnimation = Tween<double>(
      begin: -50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOut,
    ));
    
    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeIn,
    ));
    
    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedRevelationProvider>(
      builder: (context, revelationProvider, child) {
        final character = revelationProvider.characters[widget.characterCode];
        final timeline = revelationProvider.getCharacterTimelines()[widget.characterCode];
        
        if (character == null) {
          return _buildCharacterNotFound();
        }

        return Scaffold(
          body: Column(
            children: [
              // Animated header
              AnimatedBuilder(
                animation: _headerAnimationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _headerSlideAnimation.value),
                    child: Opacity(
                      opacity: _headerFadeAnimation.value,
                      child: _buildCharacterHeader(character, timeline, revelationProvider),
                    ),
                  );
                },
              ),
              
              // Tab bar
              _buildTabBar(character),
              
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(character, timeline, revelationProvider),
                    _buildAnnotationsTab(character, timeline, revelationProvider),
                    _buildTimelineTab(character, revelationProvider),
                    _buildProgressionTab(character, timeline, revelationProvider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCharacterNotFound() {
    return Scaffold(
      appBar: AppBar(title: const Text('Character Not Found')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Character not available at current revelation level'),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterHeader(EnhancedCharacter character, CharacterTimeline? timeline, EnhancedRevelationProvider provider) {
    final isDiscovered = provider.discoveredCharacters.contains(widget.characterCode);
    final characterColor = _parseColor(character.annotationStyle.color);
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            characterColor,
            characterColor.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: characterColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Character avatar and basic info
          Row(
            children: [
              // Character avatar
              Hero(
                tag: 'character_${widget.characterCode}',
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(
                    _getCharacterIcon(widget.characterCode),
                    size: 40,
                    color: characterColor,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              
              // Character details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      character.fullName,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      character.role,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      character.years,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Discovery status
              _buildDiscoveryBadge(isDiscovered),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Character stats
          _buildCharacterStats(character, timeline, provider),
        ],
      ),
    );
  }

  Widget _buildDiscoveryBadge(bool isDiscovered) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDiscovered ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDiscovered ? Icons.check_circle : Icons.lock,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            isDiscovered ? 'DISCOVERED' : 'LOCKED',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterStats(EnhancedCharacter character, CharacterTimeline? timeline, EnhancedRevelationProvider provider) {
    final annotationCount = timeline?.timeline.length ?? 0;
    final visibleCount = timeline?.timeline.where((a) => provider.isAnnotationVisible(a)).length ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          _buildStatItem('Annotations', '$visibleCount/$annotationCount', Icons.edit_note),
          const SizedBox(width: 20),
          _buildStatItem('Years Active', _getYearsActive(timeline), Icons.calendar_today),
          const SizedBox(width: 20),
          _buildStatItem('Reveal Level', character.revealLevel.level.toString(), Icons.security),
          if (character.disappearanceDate.isNotEmpty) ...[
            const SizedBox(width: 20),
            _buildStatItem('Status', 'MISSING', Icons.warning, isWarning: true),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {bool isWarning = false}) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: isWarning ? Colors.red[300] : Colors.white.withOpacity(0.8),
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isWarning ? Colors.red[300] : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(EnhancedCharacter character) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: _parseColor(character.annotationStyle.color),
        unselectedLabelColor: Colors.grey,
        indicatorColor: _parseColor(character.annotationStyle.color),
        tabs: const [
          Tab(icon: Icon(Icons.info), text: 'Overview'),
          Tab(icon: Icon(Icons.edit_note), text: 'Annotations'),
          Tab(icon: Icon(Icons.timeline), text: 'Timeline'),
          Tab(icon: Icon(Icons.trending_up), text: 'Progression'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(EnhancedCharacter character, CharacterTimeline? timeline, EnhancedRevelationProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Character description
          _buildSectionCard(
            'Character Profile',
            Icons.person,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                _buildProfileDetail('Role', character.role),
                _buildProfileDetail('Years Active', character.years),
                _buildProfileDetail('Writing Style', character.annotationStyle.description),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Mystery involvement
          _buildSectionCard(
            'Mystery Involvement',
            Icons.psychology,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  character.mysteryRole,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                if (character.keyThemes.isNotEmpty) ...[
                  Text(
                    'Key Themes:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: character.keyThemes.map((theme) => Chip(
                      label: Text(theme),
                      backgroundColor: _parseColor(character.annotationStyle.color).withOpacity(0.1),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Disappearance info (if applicable)
          if (character.disappearanceDate.isNotEmpty)
            _buildSectionCard(
              'Disappearance',
              Icons.warning,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Missing Since: ${character.disappearanceDate}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Part of ongoing investigation into Blackthorn Manor disappearances',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.red[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (timeline?.disappearanceClues.isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Disappearance Clues:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...timeline!.disappearanceClues.map((clue) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.chevron_right, size: 16, color: Colors.red),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              clue,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnnotationsTab(EnhancedCharacter character, CharacterTimeline? timeline, EnhancedRevelationProvider provider) {
    final annotations = timeline?.timeline ?? [];
    final visibleAnnotations = annotations.where((a) => provider.isAnnotationVisible(a)).toList();
    
    return Column(
      children: [
        // Annotations header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _parseColor(character.annotationStyle.color).withOpacity(0.1),
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Row(
            children: [
              Icon(Icons.edit_note, color: _parseColor(character.annotationStyle.color)),
              const SizedBox(width: 8),
              Text(
                '${visibleAnnotations.length} Annotations Available',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _parseColor(character.annotationStyle.color),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Level ${provider.currentRevelationLevel.level}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        
        // Annotations list
        Expanded(
          child: visibleAnnotations.isEmpty
              ? _buildEmptyAnnotations()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: visibleAnnotations.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final annotation = visibleAnnotations[index];
                    return _buildAnnotationCard(annotation, character, provider);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTimelineTab(EnhancedCharacter character, EnhancedRevelationProvider provider) {
    return CharacterTimelineWidget(
      focusedCharacter: widget.characterCode,
    );
  }

  Widget _buildProgressionTab(EnhancedCharacter character, CharacterTimeline? timeline, EnhancedRevelationProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Story arc progression
          _buildSectionCard(
            'Story Arc Progression',
            Icons.auto_graph,
            _buildStoryArcWidget(timeline, provider),
          ),
          
          const SizedBox(height: 16),
          
          // Discovery milestones
          _buildSectionCard(
            'Discovery Milestones',
            Icons.military_tech,
            _buildMilestonesWidget(character, provider),
          ),
          
          const SizedBox(height: 16),
          
          // Character unlock rewards
          _buildSectionCard(
            'Unlock Rewards',
            Icons.card_giftcard,
            _buildRewardsWidget(character, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Widget content) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnotationCard(EnhancedAnnotation annotation, EnhancedCharacter character, EnhancedRevelationProvider provider) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Annotation header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _parseColor(character.annotationStyle.color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Page ${annotation.pageNumber}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _parseColor(character.annotationStyle.color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (annotation.year != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${annotation.year}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const Spacer(),
                Icon(
                  annotation.isDraggable ? Icons.open_with : Icons.push_pin,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Annotation text with character styling
            Text(
              annotation.text,
              style: _getCharacterTextStyle(character.annotationStyle),
            ),
            
            const SizedBox(height: 8),
            
            // Metadata
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildMetadataChip(annotation.chapterName.replaceAll('_', ' '), Icons.book),
                _buildMetadataChip('Level ${annotation.revealLevel.level}', Icons.security),
                if (annotation.characterArcStage.isNotEmpty)
                  _buildMetadataChip(annotation.characterArcStage.replaceAll('_', ' '), Icons.psychology),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAnnotations() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.edit_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No annotations available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Advance your revelation level to unlock more content',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryArcWidget(CharacterTimeline? timeline, EnhancedRevelationProvider provider) {
    if (timeline == null) {
      return const Text('Story arc data not available');
    }
    
    final stages = ['early', 'middle', 'late', 'current'];
    final currentStage = _getCurrentStoryStage(timeline, provider);
    
    return Column(
      children: stages.map((stage) {
        final isActive = stages.indexOf(stage) <= stages.indexOf(currentStage);
        final isCurrent = stage == currentStage;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isActive ? Colors.green : Colors.grey[300],
                  shape: BoxShape.circle,
                  border: isCurrent ? Border.all(color: Colors.green, width: 2) : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getStageDescription(stage),
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? Colors.black87 : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMilestonesWidget(EnhancedCharacter character, EnhancedRevelationProvider provider) {
    final milestones = [
      'Character Discovered',
      'First Annotation Found',
      'Timeline Unlocked',
      'Mystery Role Revealed',
      'Story Arc Completed',
    ];
    
    final completedMilestones = _getCompletedMilestones(character, provider);
    
    return Column(
      children: milestones.map((milestone) {
        final isCompleted = completedMilestones.contains(milestone);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isCompleted ? Colors.green : Colors.grey[400],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  milestone,
                  style: TextStyle(
                    fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted ? Colors.black87 : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRewardsWidget(EnhancedCharacter character, EnhancedRevelationProvider provider) {
    final rewards = [
      'Character Profile Access',
      'Annotation Style Preview',
      'Timeline View Unlocked',
      'Focus Mode Available',
      'Story Arc Tracking',
    ];
    
    final isDiscovered = provider.discoveredCharacters.contains(widget.characterCode);
    
    return Column(
      children: rewards.map((reward) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                isDiscovered ? Icons.card_giftcard : Icons.lock,
                color: isDiscovered ? Colors.orange : Colors.grey[400],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  reward,
                  style: TextStyle(
                    fontWeight: isDiscovered ? FontWeight.bold : FontWeight.normal,
                    color: isDiscovered ? Colors.black87 : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Helper methods
  String _getYearsActive(CharacterTimeline? timeline) {
    if (timeline == null || timeline.timeline.isEmpty) return 'Unknown';
    
    final years = timeline.timeline
        .map((a) => a.year)
        .where((y) => y != null)
        .cast<int>()
        .toList();
    
    if (years.isEmpty) return 'Unknown';
    
    years.sort();
    return '${years.first}-${years.last}';
  }

  String _getCurrentStoryStage(CharacterTimeline timeline, EnhancedRevelationProvider provider) {
    final visibleAnnotations = timeline.timeline.where((a) => provider.isAnnotationVisible(a)).toList();
    
    if (visibleAnnotations.isEmpty) return 'early';
    if (visibleAnnotations.length < 3) return 'early';
    if (visibleAnnotations.length < 6) return 'middle';
    if (visibleAnnotations.length < 10) return 'late';
    return 'current';
  }

  String _getStageDescription(String stage) {
    switch (stage) {
      case 'early': return 'Initial Involvement';
      case 'middle': return 'Growing Investigation';
      case 'late': return 'Critical Discoveries';
      case 'current': return 'Final Phase';
      default: return stage;
    }
  }

  List<String> _getCompletedMilestones(EnhancedCharacter character, EnhancedRevelationProvider provider) {
    final milestones = <String>[];
    final isDiscovered = provider.discoveredCharacters.contains(widget.characterCode);
    final timeline = provider.getCharacterTimelines()[widget.characterCode];
    final visibleAnnotations = timeline?.timeline.where((a) => provider.isAnnotationVisible(a)).length ?? 0;
    
    if (isDiscovered) milestones.add('Character Discovered');
    if (visibleAnnotations > 0) milestones.add('First Annotation Found');
    if (visibleAnnotations > 2) milestones.add('Timeline Unlocked');
    if (character.mysteryRole.isNotEmpty) milestones.add('Mystery Role Revealed');
    if (visibleAnnotations > 8) milestones.add('Story Arc Completed');
    
    return milestones;
  }

  Color _parseColor(String colorString) {
    if (colorString.startsWith('#')) {
      return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
    }
    return AppTheme.marginaliaBlack;
  }

  IconData _getCharacterIcon(String character) {
    switch (character) {
      case 'MB': return Icons.family_restroom;
      case 'JR': return Icons.school;
      case 'EW': return Icons.engineering;
      case 'SW': return Icons.search;
      case 'Detective Sharma': return Icons.local_police;
      case 'Dr. Chambers': return Icons.government;
      default: return Icons.person;
    }
  }

  TextStyle _getCharacterTextStyle(AnnotationStyle style) {
    return TextStyle(
      fontFamily: _getFontFamily(style.fontFamily),
      fontSize: style.fontSize.toDouble(),
      color: _parseColor(style.color),
      fontStyle: style.fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
    );
  }

  String _getFontFamily(String fontFamily) {
    switch (fontFamily.toLowerCase()) {
      case 'dancing script': return 'Cursive';
      case 'courier new':
      case 'courier prime': return 'Courier';
      case 'kalam': return 'Sans-serif';
      case 'architects daughter': return 'Sans-serif';
      default: return 'Serif';
    }
  }
}