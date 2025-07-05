import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../models/enhanced_document_models.dart';
import '../providers/enhanced_revelation_provider.dart';
import '../constants/app_theme.dart';

class AdvancedCharacterDiscoveryScreen extends StatefulWidget {
  const AdvancedCharacterDiscoveryScreen({super.key});

  @override
  State<AdvancedCharacterDiscoveryScreen> createState() => _AdvancedCharacterDiscoveryScreenState();
}

class _AdvancedCharacterDiscoveryScreenState extends State<AdvancedCharacterDiscoveryScreen>
    with TickerProviderStateMixin {
  late AnimationController _discoveryController;
  late AnimationController _timelineController;
  late AnimationController _cardFlipController;
  late AnimationController _missingPersonController;
  
  late Animation<double> _discoveryAnimation;
  late Animation<double> _timelineAnimation;
  late Animation<double> _cardFlipAnimation;
  late Animation<double> _missingPersonPulse;
  
  int _selectedYear = DateTime.now().year;
  String? _selectedCharacter;
  String? _hoveredCharacter;
  bool _showMissingPersonsOnly = false;
  TimelineViewMode _viewMode = TimelineViewMode.chronological;
  
  final ScrollController _timelineScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    _discoveryController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _timelineController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _cardFlipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _missingPersonController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _discoveryAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _discoveryController,
      curve: Curves.elasticOut,
    ));
    
    _timelineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _timelineController,
      curve: Curves.easeInOut,
    ));
    
    _cardFlipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardFlipController,
      curve: Curves.easeInOut,
    ));
    
    _missingPersonPulse = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _missingPersonController,
      curve: Curves.easeInOut,
    ));
    
    _timelineController.forward();
    _missingPersonController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _discoveryController.dispose();
    _timelineController.dispose();
    _cardFlipController.dispose();
    _missingPersonController.dispose();
    _timelineScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedRevelationProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: _buildAdvancedAppBar(provider),
          body: Stack(
            children: [
              // Main content
              _buildMainContent(provider),
              
              // Discovery animations overlay
              _buildDiscoveryAnimations(provider),
              
              // Character detail overlay
              if (_selectedCharacter != null)
                _buildCharacterDetailOverlay(provider),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAdvancedAppBar(EnhancedRevelationProvider provider) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        'Character Discovery',
        style: TextStyle(
          fontFamily: 'Crimson Text',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      actions: [
        // View mode toggle
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ToggleButtons(
            isSelected: [
              _viewMode == TimelineViewMode.chronological,
              _viewMode == TimelineViewMode.byCharacter,
            ],
            onPressed: (index) {
              setState(() {
                _viewMode = index == 0 
                    ? TimelineViewMode.chronological 
                    : TimelineViewMode.byCharacter;
              });
              _timelineController.reset();
              _timelineController.forward();
            },
            borderRadius: BorderRadius.circular(20),
            children: const [
              Icon(Icons.timeline, size: 16),
              Icon(Icons.people, size: 16),
            ],
          ),
        ),
        
        // Missing persons filter
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: _showMissingPersonsOnly ? Colors.red[100] : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.person_search,
              color: _showMissingPersonsOnly ? Colors.red : Colors.grey[600],
            ),
            onPressed: () {
              setState(() {
                _showMissingPersonsOnly = !_showMissingPersonsOnly;
              });
              HapticFeedback.lightImpact();
            },
          ),
        ),
        
        // Discovery statistics
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.analytics, color: Colors.blue),
            onPressed: () => _showDiscoveryStatistics(provider),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(EnhancedRevelationProvider provider) {
    return Column(
      children: [
        // Discovery progress header
        _buildDiscoveryProgressHeader(provider),
        
        // Timeline view
        Expanded(
          child: _viewMode == TimelineViewMode.chronological
              ? _buildChronologicalTimeline(provider)
              : _buildCharacterGroupedView(provider),
        ),
      ],
    );
  }

  Widget _buildDiscoveryProgressHeader(EnhancedRevelationProvider provider) {
    final discoveredCount = provider.getDiscoveredCharacters().length;
    final totalCount = provider.characters.length;
    final progress = discoveredCount / totalCount;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.explore,
                color: Colors.blue[600],
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Discovery Progress',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              Text(
                '$discoveredCount/$totalCount',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Progress bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(Colors.blue[600]),
            minHeight: 8,
          ),
          
          const SizedBox(height: 12),
          
          // Current revelation level
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getRevelationLevelColor(provider.currentRevelationLevel),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getRevelationLevelText(provider.currentRevelationLevel),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChronologicalTimeline(EnhancedRevelationProvider provider) {
    final timelines = provider.getCharacterTimelines();
    final allEvents = <TimelineEvent>[];
    
    for (final timeline in timelines.values) {
      for (final annotation in timeline.timeline) {
        if (provider.isAnnotationVisible(annotation)) {
          allEvents.add(TimelineEvent(
            year: annotation.year ?? DateTime.now().year,
            character: annotation.character,
            event: annotation.text,
            pageNumber: annotation.pageNumber,
            importance: _getEventImportance(annotation),
          ));
        }
      }
    }
    
    allEvents.sort((a, b) => a.year.compareTo(b.year));
    
    return AnimatedBuilder(
      animation: _timelineAnimation,
      builder: (context, child) {
        return SingleChildScrollView(
          controller: _timelineScrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Year selector
                _buildYearSelector(allEvents),
                
                const SizedBox(height: 20),
                
                // Timeline
                _buildTimelineView(allEvents, provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildYearSelector(List<TimelineEvent> events) {
    final years = events.map((e) => e.year).toSet().toList()..sort();
    
    return Container(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: years.length,
        itemBuilder: (context, index) {
          final year = years[index];
          final isSelected = year == _selectedYear;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedYear = year;
              });
              HapticFeedback.lightImpact();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue[600] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ] : null,
              ),
              child: Center(
                child: Text(
                  year.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineView(List<TimelineEvent> events, EnhancedRevelationProvider provider) {
    final filteredEvents = events.where((event) {
      if (_showMissingPersonsOnly) {
        final character = provider.characters[event.character];
        return character?.isMissing == true;
      }
      return true;
    }).toList();
    
    return Column(
      children: filteredEvents.asMap().entries.map((entry) {
        final index = entry.key;
        final event = entry.value;
        
        return _buildTimelineEventCard(event, index, provider);
      }).toList(),
    );
  }

  Widget _buildTimelineEventCard(TimelineEvent event, int index, EnhancedRevelationProvider provider) {
    final character = provider.characters[event.character];
    final isLeft = index % 2 == 0;
    
    return AnimatedBuilder(
      animation: _timelineAnimation,
      builder: (context, child) {
        final slideAnimation = Tween<Offset>(
          begin: Offset(isLeft ? -1 : 1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _timelineAnimation,
          curve: Interval(
            (index * 0.1).clamp(0, 1),
            ((index * 0.1) + 0.3).clamp(0, 1),
            curve: Curves.easeOut,
          ),
        ));
        
        return SlideTransition(
          position: slideAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left side content
                  if (isLeft)
                    Expanded(
                      child: _buildEventCard(event, character, provider),
                    )
                  else
                    const Expanded(child: SizedBox()),
                  
                  // Timeline line
                  Container(
                    width: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: character?.isMissing == true ? Colors.red : Colors.blue[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Right side content
                  if (!isLeft)
                    Expanded(
                      child: _buildEventCard(event, character, provider),
                    )
                  else
                    const Expanded(child: SizedBox()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventCard(TimelineEvent event, Character? character, EnhancedRevelationProvider provider) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hoveredCharacter = event.character;
        });
      },
      onExit: (_) {
        setState(() {
          _hoveredCharacter = null;
        });
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCharacter = event.character;
          });
          _cardFlipController.forward();
          HapticFeedback.mediumImpact();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _hoveredCharacter == event.character 
                ? Colors.blue[50] 
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: character?.isMissing == true 
                  ? Colors.red[300]! 
                  : Colors.grey[300]!,
              width: _hoveredCharacter == event.character ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: _hoveredCharacter == event.character ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event header
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: character?.primaryColor ?? Colors.grey,
                    child: Text(
                      character?.name.substring(0, 2) ?? '??',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          character?.fullName ?? 'Unknown',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          event.year.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (character?.isMissing == true)
                    AnimatedBuilder(
                      animation: _missingPersonPulse,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _missingPersonPulse.value,
                          child: Icon(
                            Icons.help_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                        );
                      },
                    ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Event text
              Text(
                event.event,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Page reference
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Page ${event.pageNumber}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterGroupedView(EnhancedRevelationProvider provider) {
    final characters = provider.getDiscoveredCharacters();
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: characters.length,
      itemBuilder: (context, index) {
        final character = characters[index];
        return _buildCharacterCard(character, provider);
      },
    );
  }

  Widget _buildCharacterCard(Character character, EnhancedRevelationProvider provider) {
    final timeline = provider.getCharacterTimelines()[character.name];
    final eventCount = timeline?.timeline.length ?? 0;
    
    return AnimatedBuilder(
      animation: _discoveryAnimation,
      builder: (context, child) {
        return MouseRegion(
          onEnter: (_) {
            setState(() {
              _hoveredCharacter = character.name;
            });
          },
          onExit: (_) {
            setState(() {
              _hoveredCharacter = null;
            });
          },
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedCharacter = character.name;
              });
              _cardFlipController.forward();
              HapticFeedback.mediumImpact();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              transform: Matrix4.identity()
                ..scale(_hoveredCharacter == character.name ? 1.05 : 1.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: character.isMissing ? Colors.red[300]! : Colors.grey[300]!,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: _hoveredCharacter == character.name ? 12 : 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Character header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: character.primaryColor,
                          child: Text(
                            character.name.substring(0, 2),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                character.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                character.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (character.isMissing)
                          AnimatedBuilder(
                            animation: _missingPersonPulse,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _missingPersonPulse.value,
                                child: Icon(
                                  Icons.help_outline,
                                  color: Colors.red,
                                  size: 24,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Character description
                    Expanded(
                      child: Text(
                        character.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.3,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Statistics
                    Row(
                      children: [
                        Icon(
                          Icons.event_note,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$eventCount events',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        if (character.lastSeen != null)
                          Text(
                            'Last seen: ${character.lastSeen}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
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

  Widget _buildDiscoveryAnimations(EnhancedRevelationProvider provider) {
    return AnimatedBuilder(
      animation: _discoveryAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: DiscoveryAnimationPainter(
                animationValue: _discoveryAnimation.value,
                characters: provider.getDiscoveredCharacters(),
              ),
              size: Size.infinite,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCharacterDetailOverlay(EnhancedRevelationProvider provider) {
    final character = provider.characters[_selectedCharacter];
    if (character == null) return const SizedBox();
    
    return AnimatedBuilder(
      animation: _cardFlipAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedCharacter = null;
              });
              _cardFlipController.reverse();
            },
            child: Container(
              color: Colors.black.withOpacity(0.5 * _cardFlipAnimation.value),
              child: Center(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(_cardFlipAnimation.value * math.pi),
                  child: Container(
                    width: 350,
                    height: 500,
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: _buildCharacterDetailCard(character, provider),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCharacterDetailCard(Character character, EnhancedRevelationProvider provider) {
    final timeline = provider.getCharacterTimelines()[character.name];
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: character.primaryColor,
                child: Text(
                  character.name.substring(0, 2),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      character.fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      character.name,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (character.isMissing)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'MISSING',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Description
          Text(
            character.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Timeline events
          if (timeline != null) ...[
            Text(
              'Timeline Events',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: timeline.timeline.length,
                itemBuilder: (context, index) {
                  final annotation = timeline.timeline[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              annotation.year?.toString() ?? 'Unknown',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[600],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Page ${annotation.pageNumber}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          annotation.text,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          
          const SizedBox(height: 20),
          
          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedCharacter = null;
                });
                _cardFlipController.reverse();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: character.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getRevelationLevelColor(RevealLevel level) {
    switch (level) {
      case RevealLevel.academic:
        return Colors.blue;
      case RevealLevel.personalNotes:
        return Colors.green;
      case RevealLevel.suspiciousActivity:
        return Colors.orange;
      case RevealLevel.supernaturalEvents:
        return Colors.purple;
      case RevealLevel.completeTruth:
        return Colors.red;
    }
  }

  String _getRevelationLevelText(RevealLevel level) {
    switch (level) {
      case RevealLevel.academic:
        return 'Academic Study';
      case RevealLevel.personalNotes:
        return 'Personal Notes';
      case RevealLevel.suspiciousActivity:
        return 'Suspicious Activity';
      case RevealLevel.supernaturalEvents:
        return 'Supernatural Events';
      case RevealLevel.completeTruth:
        return 'Complete Truth';
    }
  }

  int _getEventImportance(EnhancedAnnotation annotation) {
    if (annotation.text.toLowerCase().contains('missing') ||
        annotation.text.toLowerCase().contains('disappeared')) {
      return 3; // High importance
    } else if (annotation.text.toLowerCase().contains('strange') ||
               annotation.text.toLowerCase().contains('unusual')) {
      return 2; // Medium importance
    }
    return 1; // Normal importance
  }

  void _showDiscoveryStatistics(EnhancedRevelationProvider provider) {
    showDialog(
      context: context,
      builder: (context) => CharacterDiscoveryStatisticsDialog(provider: provider),
    );
  }
}

// Supporting classes and enums
enum TimelineViewMode { chronological, byCharacter }

class TimelineEvent {
  final int year;
  final String character;
  final String event;
  final int pageNumber;
  final int importance;

  TimelineEvent({
    required this.year,
    required this.character,
    required this.event,
    required this.pageNumber,
    required this.importance,
  });
}

// Custom painter for discovery animations
class DiscoveryAnimationPainter extends CustomPainter {
  final double animationValue;
  final List<Character> characters;

  DiscoveryAnimationPainter({
    required this.animationValue,
    required this.characters,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (animationValue <= 0) return;

    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.1 * animationValue)
      ..style = PaintingStyle.fill;

    // Draw discovery waves
    for (int i = 0; i < 3; i++) {
      final radius = size.width * 0.3 * animationValue * (1 + i * 0.2);
      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.5),
        radius,
        paint,
      );
    }

    // Draw character connection lines
    if (characters.length > 1) {
      final linePaint = Paint()
        ..color = Colors.blue.withOpacity(0.2 * animationValue)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < characters.length - 1; i++) {
        final startX = size.width * 0.2 + (i * size.width * 0.6 / characters.length);
        final endX = size.width * 0.2 + ((i + 1) * size.width * 0.6 / characters.length);
        
        canvas.drawLine(
          Offset(startX, size.height * 0.5),
          Offset(endX, size.height * 0.5),
          linePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(DiscoveryAnimationPainter oldDelegate) => true;
}

// Statistics dialog
class CharacterDiscoveryStatisticsDialog extends StatelessWidget {
  final EnhancedRevelationProvider provider;

  const CharacterDiscoveryStatisticsDialog({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final stats = provider.getDiscoveryStatistics();
    final timelines = provider.getCharacterTimelines();
    
    return AlertDialog(
      title: const Text('Discovery Statistics'),
      content: Container(
        width: 400,
        height: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatSection('Overall Progress', [
                _buildStatItem('Characters Discovered', stats['characterPercentage']),
                _buildStatItem('Annotations Unlocked', stats['annotationProgress']),
                _buildStatItem('Current Level', stats['currentLevel']),
              ]),
              
              const SizedBox(height: 20),
              
              _buildStatSection('Missing Persons', [
                _buildStatItem('Total Missing', 
                  provider.characters.values.where((c) => c.isMissing).length.toString()),
                _buildStatItem('Last Seen Tracked', 
                  provider.characters.values.where((c) => c.lastSeen != null).length.toString()),
              ]),
              
              const SizedBox(height: 20),
              
              _buildStatSection('Timeline Events', [
                for (final timeline in timelines.entries)
                  _buildStatItem(timeline.key, timeline.value.timeline.length.toString()),
              ]),
            ],
          ),
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

  Widget _buildStatSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...items,
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
}