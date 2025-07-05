import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enhanced_document_models.dart';
import '../providers/enhanced_revelation_provider.dart';
import '../constants/app_theme.dart';
import 'character_timeline_widget.dart';

class MissingPersonsInvestigationWidget extends StatefulWidget {
  const MissingPersonsInvestigationWidget({super.key});

  @override
  State<MissingPersonsInvestigationWidget> createState() => _MissingPersonsInvestigationWidgetState();
}

class _MissingPersonsInvestigationWidgetState extends State<MissingPersonsInvestigationWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _alertAnimationController;
  late Animation<double> _alertPulseAnimation;
  
  String _selectedFilter = 'all';
  bool _showConnectionsMap = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    _alertAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _alertPulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _alertAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _alertAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _alertAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedRevelationProvider>(
      builder: (context, revelationProvider, child) {
        return Scaffold(
          appBar: _buildAppBar(revelationProvider),
          body: Column(
            children: [
              _buildInvestigationHeader(revelationProvider),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(revelationProvider),
                    _buildTimelineTab(revelationProvider),
                    _buildEvidenceTab(revelationProvider),
                    _buildPatternsTab(revelationProvider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(EnhancedRevelationProvider provider) {
    final activeCases = _getActiveCases(provider).length;
    
    return AppBar(
      backgroundColor: Colors.red[700],
      foregroundColor: Colors.white,
      title: Row(
        children: [
          const Icon(Icons.person_search),
          const SizedBox(width: 8),
          const Text('Missing Persons Investigation'),
          const Spacer(),
          AnimatedBuilder(
            animation: _alertPulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _alertPulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$activeCases ACTIVE',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(_showConnectionsMap ? Icons.list : Icons.account_tree),
          onPressed: () {
            setState(() {
              _showConnectionsMap = !_showConnectionsMap;
            });
          },
          tooltip: _showConnectionsMap ? 'List View' : 'Connections Map',
        ),
      ],
    );
  }

  Widget _buildInvestigationHeader(EnhancedRevelationProvider provider) {
    final cases = _getAllCases(provider);
    final activeCases = _getActiveCases(provider);
    final coldCases = _getColdCases(provider);
    final clueCount = provider.getMissingPersonsClues().length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[50]!, Colors.orange[50]!],
        ),
        border: Border(bottom: BorderSide(color: Colors.red[200]!)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatCard('Total Cases', '${cases.length}', Icons.folder, Colors.blue),
              _buildStatCard('Active', '${activeCases.length}', Icons.warning, Colors.red),
              _buildStatCard('Cold Cases', '${coldCases.length}', Icons.ac_unit, Colors.grey),
              _buildStatCard('Clues', '$clueCount', Icons.search, Colors.green),
            ],
          ),
          const SizedBox(height: 16),
          _buildFilters(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
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

  Widget _buildFilters() {
    return Row(
      children: [
        const Icon(Icons.filter_list, size: 20),
        const SizedBox(width: 8),
        const Text('Filter:'),
        const SizedBox(width: 12),
        ...['all', 'active', 'cold', 'recent'].map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_getFilterLabel(filter)),
              selected: _selectedFilter == filter,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                }
              },
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.red[700],
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.red[700],
        tabs: const [
          Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
          Tab(icon: Icon(Icons.timeline), text: 'Timeline'),
          Tab(icon: Icon(Icons.evidence), text: 'Evidence'),
          Tab(icon: Icon(Icons.psychology), text: 'Patterns'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(EnhancedRevelationProvider provider) {
    final filteredCases = _getFilteredCases(provider);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDangerAlert(provider),
          const SizedBox(height: 16),
          
          if (_showConnectionsMap)
            _buildConnectionsMap(provider)
          else
            _buildCasesList(filteredCases, provider),
        ],
      ),
    );
  }

  Widget _buildDangerAlert(EnhancedRevelationProvider provider) {
    if (provider.currentRevelationLevel.level < 4) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red[700], size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'ACTIVE SUPERNATURAL THREAT DETECTED',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Pattern analysis indicates ongoing dimensional incursions at Blackthorn Manor. All investigators are advised to exercise extreme caution.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.red[600],
            ),
          ),
          if (provider.currentRevelationLevel.level >= 5) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.withOpacity(0.3)),
              ),
              child: Text(
                'CLASSIFIED: Department 8 has been monitoring these anomalies since 1866. The manor serves as a dimensional nexus point.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.purple[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCasesList(List<MissingPersonCase> cases, EnhancedRevelationProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Missing Persons Cases (${cases.length})',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        ...cases.map((missingCase) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildCaseCard(missingCase, provider),
        )).toList(),
      ],
    );
  }

  Widget _buildCaseCard(MissingPersonCase missingCase, EnhancedRevelationProvider provider) {
    final character = provider.characters[missingCase.characterCode];
    final isActive = missingCase.status == 'active';
    
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? Colors.red[300]! : Colors.grey[300]!,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Case header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getCharacterColor(character),
                    child: Icon(
                      _getCharacterIcon(missingCase.characterCode),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          character?.fullName ?? missingCase.characterCode,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          character?.role ?? 'Unknown',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(missingCase.status),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Case details
              _buildCaseDetail('Last Seen', missingCase.lastSeen),
              _buildCaseDetail('Location', missingCase.location),
              _buildCaseDetail('Days Missing', '${missingCase.daysMissing}'),
              
              if (missingCase.clues.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Evidence & Clues:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                ...missingCase.clues.take(3).map((clue) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Icon(Icons.chevron_right, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          clue,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                if (missingCase.clues.length > 3)
                  Text(
                    '+ ${missingCase.clues.length - 3} more clues...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
              
              const SizedBox(height: 12),
              
              // Case actions
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _viewCharacterTimeline(missingCase.characterCode),
                    icon: const Icon(Icons.timeline, size: 16),
                    label: const Text('View Timeline'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _viewConnections(missingCase.characterCode),
                    icon: const Icon(Icons.account_tree, size: 16),
                    label: const Text('Connections'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaseDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    
    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.red;
        icon = Icons.warning;
        break;
      case 'cold':
        color = Colors.blue;
        icon = Icons.ac_unit;
        break;
      case 'resolved':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionsMap(EnhancedRevelationProvider provider) {
    final cases = _getAllCases(provider);
    
    return Container(
      height: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Text(
            'Investigation Connections Map',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CustomPaint(
              painter: ConnectionsMapPainter(cases),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTab(EnhancedRevelationProvider provider) {
    return CharacterTimelineWidget(
      showMissingPersonsOnly: true,
    );
  }

  Widget _buildEvidenceTab(EnhancedRevelationProvider provider) {
    final allClues = provider.getMissingPersonsClues();
    final categorizedClues = _categorizeClues(allClues);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evidence Collection',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          ...categorizedClues.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildEvidenceCategory(entry.key, entry.value),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildEvidenceCategory(String category, List<String> clues) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getCategoryIcon(category)),
                const SizedBox(width: 8),
                Text(
                  category,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${clues.length} items',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...clues.map((clue) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.fiber_manual_record, size: 8, color: Colors.grey[600]),
                  const SizedBox(width: 8),
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
        ),
      ),
    );
  }

  Widget _buildPatternsTab(EnhancedRevelationProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pattern Analysis',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildPatternCard(
            'Temporal Patterns',
            Icons.schedule,
            _getTemporalPatterns(provider),
          ),
          
          const SizedBox(height: 16),
          
          _buildPatternCard(
            'Location Patterns',
            Icons.location_on,
            _getLocationPatterns(provider),
          ),
          
          const SizedBox(height: 16),
          
          _buildPatternCard(
            'Behavioral Patterns',
            Icons.psychology,
            _getBehavioralPatterns(provider),
          ),
          
          if (provider.currentRevelationLevel.level >= 5) ...[
            const SizedBox(height: 16),
            _buildPatternCard(
              'Supernatural Patterns',
              Icons.auto_awesome,
              _getSupernaturalPatterns(provider),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPatternCard(String title, IconData icon, List<String> patterns) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.red[700]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...patterns.map((pattern) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.trending_up, size: 16, color: Colors.red[400]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pattern,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  // Helper methods
  List<MissingPersonCase> _getAllCases(EnhancedRevelationProvider provider) {
    final cases = <MissingPersonCase>[];
    final disappearanceDates = provider.getDisappearanceDates();
    
    for (final entry in disappearanceDates.entries) {
      final character = provider.characters[entry.key];
      if (character != null) {
        cases.add(MissingPersonCase(
          characterCode: entry.key,
          lastSeen: entry.value,
          location: 'Blackthorn Manor',
          status: _determineStatus(entry.value),
          daysMissing: _calculateDaysMissing(entry.value),
          clues: _getCluesForCharacter(entry.key, provider),
        ));
      }
    }
    
    return cases;
  }

  List<MissingPersonCase> _getActiveCases(EnhancedRevelationProvider provider) {
    return _getAllCases(provider).where((c) => c.status == 'active').toList();
  }

  List<MissingPersonCase> _getColdCases(EnhancedRevelationProvider provider) {
    return _getAllCases(provider).where((c) => c.status == 'cold').toList();
  }

  List<MissingPersonCase> _getFilteredCases(EnhancedRevelationProvider provider) {
    final allCases = _getAllCases(provider);
    
    switch (_selectedFilter) {
      case 'active':
        return allCases.where((c) => c.status == 'active').toList();
      case 'cold':
        return allCases.where((c) => c.status == 'cold').toList();
      case 'recent':
        return allCases.where((c) => c.daysMissing < 365).toList();
      default:
        return allCases;
    }
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'all': return 'All Cases';
      case 'active': return 'Active';
      case 'cold': return 'Cold Cases';
      case 'recent': return 'Recent';
      default: return filter;
    }
  }

  String _determineStatus(String disappearanceDate) {
    if (disappearanceDate.contains('2024') || disappearanceDate.contains('Active')) {
      return 'active';
    }
    return 'cold';
  }

  int _calculateDaysMissing(String disappearanceDate) {
    final now = DateTime.now();
    // Simple calculation - in real app would parse actual date
    if (disappearanceDate.contains('2024')) return 30;
    if (disappearanceDate.contains('1999')) return (now.year - 1999) * 365;
    if (disappearanceDate.contains('1989')) return (now.year - 1989) * 365;
    return 365;
  }

  List<String> _getCluesForCharacter(String characterCode, EnhancedRevelationProvider provider) {
    final timeline = provider.getCharacterTimelines()[characterCode];
    if (timeline == null) return [];
    
    return timeline.disappearanceClues;
  }

  Map<String, List<String>> _categorizeClues(List<String> clues) {
    final categories = <String, List<String>>{
      'Physical Evidence': [],
      'Witness Accounts': [],
      'Behavioral Changes': [],
      'Environmental Anomalies': [],
      'Documentation': [],
    };
    
    for (final clue in clues) {
      final lower = clue.toLowerCase();
      if (lower.contains('found') || lower.contains('object') || lower.contains('item')) {
        categories['Physical Evidence']!.add(clue);
      } else if (lower.contains('saw') || lower.contains('witness') || lower.contains('reported')) {
        categories['Witness Accounts']!.add(clue);
      } else if (lower.contains('behavior') || lower.contains('acting') || lower.contains('mood')) {
        categories['Behavioral Changes']!.add(clue);
      } else if (lower.contains('temperature') || lower.contains('lights') || lower.contains('sound')) {
        categories['Environmental Anomalies']!.add(clue);
      } else {
        categories['Documentation']!.add(clue);
      }
    }
    
    // Remove empty categories
    categories.removeWhere((key, value) => value.isEmpty);
    
    return categories;
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Physical Evidence': return Icons.inventory;
      case 'Witness Accounts': return Icons.visibility;
      case 'Behavioral Changes': return Icons.psychology;
      case 'Environmental Anomalies': return Icons.thermostat;
      case 'Documentation': return Icons.description;
      default: return Icons.help;
    }
  }

  List<String> _getTemporalPatterns(EnhancedRevelationProvider provider) {
    return [
      'Disappearances occur in clusters separated by decades',
      'Peak activity during winter months (December-February)',
      'Most incidents happen between 2:00 AM and 4:00 AM',
      'Pattern repeats every 30-35 years',
    ];
  }

  List<String> _getLocationPatterns(EnhancedRevelationProvider provider) {
    return [
      'All disappearances occur within 100m radius of the manor',
      'East wing shows highest concentration of incidents',
      'Basement and attic levels show elevated risk',
      'No incidents reported in the main foyer or kitchen areas',
    ];
  }

  List<String> _getBehavioralPatterns(EnhancedRevelationProvider provider) {
    return [
      'Subjects show increased interest in manor history before disappearing',
      'Sleep disturbances reported in 85% of cases',
      'Unexplained knowledge of manor layout despite first visit',
      'Compulsive note-taking and documentation behavior',
    ];
  }

  List<String> _getSupernaturalPatterns(EnhancedRevelationProvider provider) {
    return [
      'Electromagnetic anomalies precede each incident',
      'Dimensional instability detected during disappearances',
      'Subjects may be existing in parallel dimensional space',
      'Department 8 monitoring confirms otherworldly entities',
    ];
  }

  void _viewCharacterTimeline(String characterCode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text('Timeline: $characterCode')),
          body: CharacterTimelineWidget(focusedCharacter: characterCode),
        ),
      ),
    );
  }

  void _viewConnections(String characterCode) {
    // Would show detailed connection analysis
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Connections: $characterCode'),
        content: const Text('Detailed connection analysis would be shown here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
}

// Data models for missing persons investigation
class MissingPersonCase {
  final String characterCode;
  final String lastSeen;
  final String location;
  final String status;
  final int daysMissing;
  final List<String> clues;

  MissingPersonCase({
    required this.characterCode,
    required this.lastSeen,
    required this.location,
    required this.status,
    required this.daysMissing,
    required this.clues,
  });
}

// Custom painter for connections map
class ConnectionsMapPainter extends CustomPainter {
  final List<MissingPersonCase> cases;

  ConnectionsMapPainter(this.cases);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..strokeWidth = 2;

    // Draw simple network visualization
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = 60.0;

    // Central node (Blackthorn Manor)
    canvas.drawCircle(
      Offset(centerX, centerY),
      20,
      Paint()..color = Colors.red,
    );

    // Case nodes around the center
    for (int i = 0; i < cases.length; i++) {
      final angle = (i * 2 * 3.14159) / cases.length;
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);

      // Draw connection line
      canvas.drawLine(
        Offset(centerX, centerY),
        Offset(x, y),
        paint,
      );

      // Draw case node
      canvas.drawCircle(
        Offset(x, y),
        15,
        Paint()..color = cases[i].status == 'active' ? Colors.red : Colors.blue,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Missing import
import 'dart:math' as math;