import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enhanced_document_models.dart';
import '../providers/enhanced_revelation_provider.dart';
import '../constants/app_theme.dart';

class CharacterTimelineWidget extends StatefulWidget {
  final String? focusedCharacter;
  final bool showMissingPersonsOnly;

  const CharacterTimelineWidget({
    super.key,
    this.focusedCharacter,
    this.showMissingPersonsOnly = false,
  });

  @override
  State<CharacterTimelineWidget> createState() => _CharacterTimelineWidgetState();
}

class _CharacterTimelineWidgetState extends State<CharacterTimelineWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late ScrollController _scrollController;
  String? _selectedCharacter;
  int _selectedYear = DateTime.now().year;
  bool _showAllYears = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scrollController = ScrollController();
    _selectedCharacter = widget.focusedCharacter;
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedRevelationProvider>(
      builder: (context, revelationProvider, child) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                children: [
                  _buildTimelineHeader(revelationProvider),
                  const SizedBox(height: 16),
                  _buildCharacterSelector(revelationProvider),
                  const SizedBox(height: 16),
                  _buildYearFilter(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildTimelineContent(revelationProvider),
                  ),
                  _buildMysteryInsights(revelationProvider),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimelineHeader(EnhancedRevelationProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.marginaliaBlack.withOpacity(0.1),
            AppTheme.marginaliaBlack.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            widget.showMissingPersonsOnly 
                ? Icons.person_search 
                : Icons.timeline,
            size: 32,
            color: AppTheme.marginaliaBlack,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.showMissingPersonsOnly 
                      ? 'Missing Persons Investigation'
                      : _selectedCharacter != null
                          ? 'Character Timeline: ${provider.characters[_selectedCharacter]?.fullName ?? _selectedCharacter}'
                          : 'Character Timeline Explorer',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.showMissingPersonsOnly
                      ? 'Tracking disappearances across 158 years'
                      : 'Chronological story development (1866-2024)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          _buildRevelationBadge(provider),
        ],
      ),
    );
  }

  Widget _buildRevelationBadge(EnhancedRevelationProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getRevelationLevelColor(provider.currentRevelationLevel),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Level ${provider.currentRevelationLevel.level}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildCharacterSelector(EnhancedRevelationProvider provider) {
    final availableCharacters = provider.availableCharacters;
    
    return Container(
      height: 100,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // All Characters option
            _buildCharacterCard(
              null,
              'All Characters',
              'View complete timeline',
              Icons.people,
              provider,
            ),
            const SizedBox(width: 8),
            
            // Individual character cards
            ...availableCharacters.map((characterCode) {
              final character = provider.characters[characterCode];
              if (character == null) return const SizedBox.shrink();
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildCharacterCard(
                  characterCode,
                  character.name,
                  character.role,
                  _getCharacterIcon(characterCode),
                  provider,
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterCard(
    String? characterCode,
    String name,
    String subtitle,
    IconData icon,
    EnhancedRevelationProvider provider,
  ) {
    final isSelected = _selectedCharacter == characterCode;
    final character = characterCode != null ? provider.characters[characterCode] : null;
    final isDiscovered = characterCode == null || provider.discoveredCharacters.contains(characterCode);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCharacter = characterCode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? _getCharacterColor(character) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _getCharacterColor(character) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: _getCharacterColor(character).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : (isDiscovered ? _getCharacterColor(character) : Colors.grey),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? Colors.white : (isDiscovered ? Colors.black87 : Colors.grey),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected ? Colors.white70 : Colors.grey[600],
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!isDiscovered && characterCode != null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'LOCKED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range, size: 20),
          const SizedBox(width: 8),
          Text(
            'Filter by Year:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(width: 16),
          
          // All Years toggle
          FilterChip(
            label: const Text('All Years'),
            selected: _showAllYears,
            onSelected: (selected) {
              setState(() {
                _showAllYears = selected;
              });
            },
          ),
          const SizedBox(width: 8),
          
          // Specific year ranges
          ...['1866-1900', '1900-1950', '1950-2000', '2000-2024'].map((range) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(range),
                selected: !_showAllYears && _getYearRangeSelected(range),
                onSelected: (selected) {
                  setState(() {
                    _showAllYears = false;
                    _selectedYear = _getYearFromRange(range);
                  });
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTimelineContent(EnhancedRevelationProvider provider) {
    final timelines = provider.getCharacterTimelines();
    final events = _buildTimelineEvents(timelines, provider);
    
    if (events.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        separatorBuilder: (context, index) => _buildTimelineConnector(),
        itemBuilder: (context, index) {
          final event = events[index];
          return _buildTimelineEvent(event, provider);
        },
      ),
    );
  }

  Widget _buildTimelineConnector() {
    return Container(
      height: 20,
      child: Row(
        children: [
          const SizedBox(width: 30),
          Container(
            width: 2,
            height: 20,
            color: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineEvent(TimelineEvent event, EnhancedRevelationProvider provider) {
    final character = provider.characters[event.character];
    final isVisible = provider.isAnnotationVisible(event.annotation);
    
    return Opacity(
      opacity: isVisible ? 1.0 : 0.3,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline marker
          _buildTimelineMarker(event, character),
          const SizedBox(width: 16),
          
          // Event content
          Expanded(
            child: _buildEventContent(event, character, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineMarker(TimelineEvent event, EnhancedCharacter? character) {
    return Container(
      width: 60,
      child: Column(
        children: [
          // Year badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getCharacterColor(character),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${event.year ?? '????'}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 4),
          
          // Character marker
          CircleAvatar(
            radius: 20,
            backgroundColor: _getCharacterColor(character),
            child: Icon(
              _getCharacterIcon(event.character),
              color: Colors.white,
              size: 20,
            ),
          ),
          
          // Event type indicator
          if (event.isDisappearance)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning,
                color: Colors.white,
                size: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventContent(TimelineEvent event, EnhancedCharacter? character, EnhancedRevelationProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getCharacterColor(character).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getCharacterColor(character).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event header
          Row(
            children: [
              Expanded(
                child: Text(
                  character?.fullName ?? event.character,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _getCharacterColor(character),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (event.isDisappearance)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'MISSING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Annotation text
          Text(
            event.annotation.text,
            style: _getCharacterTextStyle(character?.annotationStyle),
          ),
          
          const SizedBox(height: 8),
          
          // Event metadata
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildMetadataChip('Page ${event.annotation.pageNumber}', Icons.book),
              _buildMetadataChip(event.annotation.chapterName.replaceAll('_', ' '), Icons.chapter_outlined),
              if (event.annotation.characterArcStage.isNotEmpty)
                _buildMetadataChip(event.annotation.characterArcStage.replaceAll('_', ' '), Icons.psychology),
              _buildMetadataChip('Level ${event.annotation.revealLevel.level}', Icons.security),
            ],
          ),
          
          // Mystery connections
          if (event.mysteryConnections.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Mystery Connections:',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            ...event.mysteryConnections.map((connection) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.link, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      connection,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ],
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
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMysteryInsights(EnhancedRevelationProvider provider) {
    final insights = _generateMysteryInsights(provider);
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.1),
            Colors.orange.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                'Mystery Analysis',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...insights.map((insight) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.chevron_right, size: 16, color: Colors.red[400]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    insight,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No timeline events available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discover more characters to unlock their stories',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  List<TimelineEvent> _buildTimelineEvents(Map<String, CharacterTimeline> timelines, EnhancedRevelationProvider provider) {
    final events = <TimelineEvent>[];
    
    for (final timeline in timelines.values) {
      final character = timeline.character;
      
      // Skip if character is selected and this isn't the selected character
      if (_selectedCharacter != null && character != _selectedCharacter) {
        continue;
      }
      
      // Skip if showing missing persons only and character hasn't disappeared
      if (widget.showMissingPersonsOnly && timeline.disappearanceDate.isEmpty) {
        continue;
      }
      
      for (final annotation in timeline.timeline) {
        // Skip if not in year range
        if (!_showAllYears && !_isInYearRange(annotation.year)) {
          continue;
        }
        
        events.add(TimelineEvent(
          character: character,
          annotation: annotation,
          year: annotation.year,
          isDisappearance: timeline.disappearanceClues.any((clue) => 
            clue.toLowerCase().contains('disappear') && 
            annotation.text.toLowerCase().contains(clue.toLowerCase().split(' ').first)),
          mysteryConnections: _findMysteryConnections(annotation, timelines),
        ));
      }
    }
    
    // Sort by year
    events.sort((a, b) {
      final yearA = a.year ?? 0;
      final yearB = b.year ?? 0;
      return yearA.compareTo(yearB);
    });
    
    return events;
  }

  List<String> _findMysteryConnections(EnhancedAnnotation annotation, Map<String, CharacterTimeline> timelines) {
    final connections = <String>[];
    final keywords = annotation.text.toLowerCase().split(' ');
    
    for (final timeline in timelines.values) {
      if (timeline.character == annotation.character) continue;
      
      for (final otherAnnotation in timeline.timeline) {
        final otherKeywords = otherAnnotation.text.toLowerCase().split(' ');
        final commonKeywords = keywords.where((k) => otherKeywords.contains(k) && k.length > 3).toList();
        
        if (commonKeywords.isNotEmpty) {
          connections.add('Related to ${timeline.character}: ${commonKeywords.join(', ')}');
        }
      }
    }
    
    return connections.take(3).toList();
  }

  List<String> _generateMysteryInsights(EnhancedRevelationProvider provider) {
    final insights = <String>[];
    final disappearanceDates = provider.getDisappearanceDates();
    final clues = provider.getMissingPersonsClues();
    
    if (disappearanceDates.isNotEmpty) {
      insights.add('${disappearanceDates.length} documented disappearances');
    }
    
    if (clues.isNotEmpty) {
      insights.add('${clues.length} clues found across investigations');
    }
    
    if (provider.currentRevelationLevel.level >= 4) {
      insights.add('Pattern detected: All disappearances occur near dimensional events');
    }
    
    if (provider.currentRevelationLevel.level >= 5) {
      insights.add('Government involvement confirmed - Department 8 active since 1866');
    }
    
    return insights;
  }

  bool _isInYearRange(int? year) {
    if (year == null) return false;
    
    switch (_selectedYear) {
      case 1866: return year >= 1866 && year <= 1900;
      case 1900: return year >= 1900 && year <= 1950;
      case 1950: return year >= 1950 && year <= 2000;
      case 2000: return year >= 2000 && year <= 2024;
      default: return true;
    }
  }

  bool _getYearRangeSelected(String range) {
    switch (range) {
      case '1866-1900': return _selectedYear == 1866;
      case '1900-1950': return _selectedYear == 1900;
      case '1950-2000': return _selectedYear == 1950;
      case '2000-2024': return _selectedYear == 2000;
      default: return false;
    }
  }

  int _getYearFromRange(String range) {
    switch (range) {
      case '1866-1900': return 1866;
      case '1900-1950': return 1900;
      case '1950-2000': return 1950;
      case '2000-2024': return 2000;
      default: return DateTime.now().year;
    }
  }

  Color _getCharacterColor(EnhancedCharacter? character) {
    if (character == null) return Colors.grey;
    return _parseColor(character.annotationStyle.color);
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

  TextStyle? _getCharacterTextStyle(AnnotationStyle? style) {
    if (style == null) return null;
    
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

  Color _getRevelationLevelColor(RevealLevel level) {
    switch (level) {
      case RevealLevel.academic: return Colors.grey;
      case RevealLevel.familySecrets: return Colors.blue;
      case RevealLevel.investigation: return Colors.orange;
      case RevealLevel.modernMystery: return Colors.red;
      case RevealLevel.completeTruth: return Colors.purple;
    }
  }
}

// Data models for timeline events
class TimelineEvent {
  final String character;
  final EnhancedAnnotation annotation;
  final int? year;
  final bool isDisappearance;
  final List<String> mysteryConnections;

  TimelineEvent({
    required this.character,
    required this.annotation,
    required this.year,
    required this.isDisappearance,
    required this.mysteryConnections,
  });
}