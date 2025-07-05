import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import '../../services/investigation_service.dart';

class EvidenceCollectionWidget extends StatefulWidget {
  final String pageContent;
  final int pageNumber;
  final List<dynamic> annotations;
  final VoidCallback? onEvidenceCollected;

  const EvidenceCollectionWidget({
    super.key,
    required this.pageContent,
    required this.pageNumber,
    this.annotations = const [],
    this.onEvidenceCollected,
  });

  @override
  State<EvidenceCollectionWidget> createState() => _EvidenceCollectionWidgetState();
}

class _EvidenceCollectionWidgetState extends State<EvidenceCollectionWidget>
    with TickerProviderStateMixin {
  final InvestigationService _investigationService = InvestigationService();
  
  late AnimationController _scanController;
  late AnimationController _collectController;
  late AnimationController _magnifyController;
  
  late Animation<double> _scanAnimation;
  late Animation<double> _collectAnimation;
  late Animation<double> _magnifyAnimation;
  
  bool _isMagnifying = false;
  bool _isScanning = false;
  List<EvidenceClue> _detectedClues = [];
  EvidenceClue? _selectedClue;
  String _selectedTool = 'magnifying_glass';
  
  final GlobalKey _contentKey = GlobalKey();
  
  @override
  void initState() {
    super.initState();
    
    _scanController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _collectController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _magnifyController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
    
    _collectAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _collectController, curve: Curves.elasticOut),
    );
    
    _magnifyAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _magnifyController, curve: Curves.easeInOut),
    );
    
    _initializeInvestigation();
    _scanForEvidence();
  }

  @override
  void dispose() {
    _scanController.dispose();
    _collectController.dispose();
    _magnifyController.dispose();
    super.dispose();
  }

  Future<void> _initializeInvestigation() async {
    await _investigationService.initialize();
    if (mounted) setState(() {});
  }

  void _scanForEvidence() {
    setState(() {
      _isScanning = true;
      _detectedClues.clear();
    });
    
    _scanController.forward().then((_) {
      _detectEvidenceClues();
      setState(() {
        _isScanning = false;
      });
      _scanController.reset();
    });
  }

  void _detectEvidenceClues() {
    final clues = <EvidenceClue>[];
    
    // Scan page content for evidence patterns
    _scanTextForEvidence(widget.pageContent, clues);
    
    // Scan annotations for evidence
    for (final annotation in widget.annotations) {
      _scanAnnotationForEvidence(annotation, clues);
    }
    
    // Add page-specific evidence opportunities
    _addPageSpecificEvidence(widget.pageNumber, clues);
    
    setState(() {
      _detectedClues = clues;
    });
  }

  void _scanTextForEvidence(String content, List<EvidenceClue> clues) {
    // Temperature/thermal references
    if (content.toLowerCase().contains(RegExp(r'cold|temperature|thermal|chill'))) {
      clues.add(EvidenceClue(
        id: 'thermal_reference_${widget.pageNumber}',
        title: 'Temperature Anomaly Reference',
        description: 'Text mentions temperature variations - potential thermal evidence',
        type: EvidenceType.physical,
        position: _findTextPosition(content, RegExp(r'cold|temperature|thermal|chill')),
        rarity: EvidenceRarity.common,
        relevance: 0.7,
        isHidden: false,
      ));
    }
    
    // Date references
    final dateMatches = RegExp(r'\b(18|19|20)\d{2}\b').allMatches(content);
    for (final match in dateMatches) {
      clues.add(EvidenceClue(
        id: 'date_reference_${match.start}',
        title: 'Historical Date Reference',
        description: 'Date mentioned: ${match.group(0)} - check timeline significance',
        type: EvidenceType.document,
        position: Offset(match.start.toDouble(), 0),
        rarity: EvidenceRarity.common,
        relevance: 0.6,
        isHidden: false,
      ));
    }
    
    // Redacted content
    if (content.contains('█')) {
      clues.add(EvidenceClue(
        id: 'redacted_content_${widget.pageNumber}',
        title: 'Redacted Information',
        description: 'Hidden information that may be revealed with higher revelation levels',
        type: EvidenceType.official,
        position: _findTextPosition(content, RegExp(r'█+')),
        rarity: EvidenceRarity.rare,
        relevance: 0.9,
        isHidden: true,
      ));
    }
    
    // Suspicious phrases
    final suspiciousPatterns = [
      r'disappeared?|vanished?|missing',
      r'strange|unusual|odd|peculiar',
      r'sound|noise|voice|whisper',
      r'shadow|figure|silhouette',
    ];
    
    for (final pattern in suspiciousPatterns) {
      if (content.toLowerCase().contains(RegExp(pattern))) {
        clues.add(EvidenceClue(
          id: 'suspicious_${pattern.hashCode}_${widget.pageNumber}',
          title: 'Suspicious Reference',
          description: 'Text contains potentially significant information',
          type: EvidenceType.document,
          position: _findTextPosition(content, RegExp(pattern)),
          rarity: EvidenceRarity.uncommon,
          relevance: 0.5,
          isHidden: false,
        ));
      }
    }
  }

  void _scanAnnotationForEvidence(dynamic annotation, List<EvidenceClue> clues) {
    if (annotation is Map<String, dynamic>) {
      final character = annotation['character'] as String? ?? '';
      final text = annotation['text'] as String? ?? '';
      final year = annotation['year'] as int?;
      
      // Character-specific evidence
      if (character == 'JR' && text.toLowerCase().contains('equipment')) {
        clues.add(EvidenceClue(
          id: 'equipment_reference_${character}_${widget.pageNumber}',
          title: 'Equipment Reference',
          description: 'James Reed mentions modern detection equipment',
          type: EvidenceType.digital,
          position: const Offset(100, 100), // Annotation position
          rarity: EvidenceRarity.uncommon,
          relevance: 0.8,
          isHidden: false,
        ));
      }
      
      // Temporal evidence
      if (year != null && year < 1970) {
        clues.add(EvidenceClue(
          id: 'historical_annotation_${character}_$year',
          title: 'Historical Account',
          description: 'Early eyewitness account from $year',
          type: EvidenceType.document,
          position: const Offset(150, 50),
          rarity: EvidenceRarity.rare,
          relevance: 0.85,
          isHidden: false,
        ));
      }
      
      // Missing person references
      if (text.toLowerCase().contains(RegExp(r'missing|disappeared|last seen'))) {
        clues.add(EvidenceClue(
          id: 'missing_person_${character}_${widget.pageNumber}',
          title: 'Missing Person Reference',
          description: 'Reference to someone who disappeared',
          type: EvidenceType.official,
          position: const Offset(200, 75),
          rarity: EvidenceRarity.rare,
          relevance: 0.95,
          isHidden: false,
        ));
      }
    }
  }

  void _addPageSpecificEvidence(int pageNumber, List<EvidenceClue> clues) {
    // Add evidence based on specific pages
    switch (pageNumber) {
      case 1:
        clues.add(EvidenceClue(
          id: 'finch_survey_notes',
          title: 'Professor Finch\'s Survey Notes',
          description: 'Original architectural survey from 1963',
          type: EvidenceType.document,
          position: const Offset(50, 200),
          rarity: EvidenceRarity.uncommon,
          relevance: 0.85,
          isHidden: false,
        ));
        break;
      case 2:
        clues.add(EvidenceClue(
          id: 'thermal_anomaly_east',
          title: 'Thermal Anomaly - East Wing',
          description: 'Consistent cold spot detected in foundation',
          type: EvidenceType.physical,
          position: const Offset(75, 150),
          rarity: EvidenceRarity.rare,
          relevance: 0.9,
          isHidden: false,
        ));
        break;
      case 3:
        clues.add(EvidenceClue(
          id: 'margaret_diary_1963',
          title: 'Margaret\'s Diary Entry',
          description: 'Personal account of unusual occurrences',
          type: EvidenceType.document,
          position: const Offset(120, 100),
          rarity: EvidenceRarity.uncommon,
          relevance: 0.8,
          isHidden: false,
        ));
        break;
    }
  }

  Offset _findTextPosition(String content, RegExp pattern) {
    final match = pattern.firstMatch(content.toLowerCase());
    if (match != null) {
      final lines = content.substring(0, match.start).split('\n');
      return Offset(match.start.toDouble() % 50, lines.length * 20.0);
    }
    return Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Investigation toolbar
        _buildInvestigationToolbar(),
        
        const SizedBox(height: 16),
        
        // Content area with evidence overlay
        Expanded(
          child: Stack(
            children: [
              // Main content
              _buildContentArea(),
              
              // Evidence overlay
              if (_detectedClues.isNotEmpty) _buildEvidenceOverlay(),
              
              // Scanning overlay
              if (_isScanning) _buildScanningOverlay(),
              
              // Tool-specific overlays
              if (_isMagnifying) _buildMagnifyingOverlay(),
            ],
          ),
        ),
        
        // Evidence collection panel
        if (_detectedClues.isNotEmpty) _buildEvidencePanel(),
      ],
    );
  }

  Widget _buildInvestigationToolbar() {
    final tools = _investigationService.tools;
    final unlockedTools = _investigationService.unlockedTools;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.build, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Investigation Tools',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _scanForEvidence,
                icon: Icon(
                  _isScanning ? Icons.refresh : Icons.search,
                  color: Colors.blue[600],
                ),
                tooltip: 'Scan for Evidence',
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Tool selection
          Wrap(
            spacing: 8,
            children: tools.entries.map((entry) {
              final tool = entry.value;
              final isUnlocked = unlockedTools.contains(tool.id);
              final isSelected = _selectedTool == tool.id;
              
              return GestureDetector(
                onTap: isUnlocked ? () => _selectTool(tool.id) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.blue[500] 
                        : isUnlocked 
                            ? Colors.white 
                            : Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected 
                          ? Colors.blue[700]! 
                          : isUnlocked 
                              ? Colors.grey[400]! 
                              : Colors.grey[500]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tool.icon,
                        style: TextStyle(
                          fontSize: 16,
                          color: isUnlocked ? null : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tool.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected 
                              ? Colors.white 
                              : isUnlocked 
                                  ? Colors.grey[800] 
                                  : Colors.grey[600],
                        ),
                      ),
                      if (!isUnlocked) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.lock,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea() {
    return Container(
      key: _contentKey,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page content
          Text(
            widget.pageContent,
            style: const TextStyle(
              fontSize: 16,
              lineHeight: 1.6,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Annotations
          if (widget.annotations.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Annotations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            ...widget.annotations.map((annotation) => _buildAnnotationDisplay(annotation)),
          ],
        ],
      ),
    );
  }

  Widget _buildAnnotationDisplay(dynamic annotation) {
    if (annotation is! Map<String, dynamic>) return const SizedBox();
    
    final character = annotation['character'] as String? ?? '';
    final text = annotation['text'] as String? ?? '';
    final year = annotation['year'] as int?;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: _getCharacterColor(character),
                child: Text(
                  character.isNotEmpty ? character[0] : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                character,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              if (year != null) ...[
                const SizedBox(width: 8),
                Text(
                  year.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceOverlay() {
    return Positioned.fill(
      child: Stack(
        children: _detectedClues.map((clue) => _buildEvidenceMarker(clue)).toList(),
      ),
    );
  }

  Widget _buildEvidenceMarker(EvidenceClue clue) {
    final isSelected = _selectedClue?.id == clue.id;
    
    return Positioned(
      left: clue.position.dx,
      top: clue.position.dy,
      child: GestureDetector(
        onTap: () => _selectClue(clue),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: Stack(
            children: [
              // Pulsing indicator
              AnimatedBuilder(
                animation: _scanAnimation,
                builder: (context, child) {
                  return Container(
                    width: 30 + (10 * _scanAnimation.value),
                    height: 30 + (10 * _scanAnimation.value),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getEvidenceColor(clue.rarity).withOpacity(0.3 * (1 - _scanAnimation.value)),
                    ),
                  );
                },
              ),
              
              // Main marker
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getEvidenceColor(clue.rarity),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getEvidenceColor(clue.rarity).withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _getEvidenceIcon(clue.type),
                  color: Colors.white,
                  size: 16,
                ),
              ),
              
              // Hidden indicator
              if (clue.isHidden)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 8,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEvidencePanel() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Evidence Detected: ${_detectedClues.length}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              if (_selectedClue != null)
                ElevatedButton.icon(
                  onPressed: () => _collectEvidence(_selectedClue!),
                  icon: const Icon(Icons.add_circle, size: 16),
                  label: const Text('Collect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Evidence list
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _detectedClues.length,
              itemBuilder: (context, index) {
                final clue = _detectedClues[index];
                final isSelected = _selectedClue?.id == clue.id;
                
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => _selectClue(clue),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[50] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getEvidenceColor(clue.rarity),
                                ),
                                child: Icon(
                                  _getEvidenceIcon(clue.type),
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  clue.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (clue.isHidden)
                                Icon(
                                  Icons.lock,
                                  size: 12,
                                  color: Colors.red[600],
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            clue.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getEvidenceColor(clue.rarity).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  clue.rarity.toString().split('.').last.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _getEvidenceColor(clue.rarity),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${(clue.relevance * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return AnimatedBuilder(
      animation: _scanAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.withOpacity(0.1 * _scanAnimation.value),
                  Colors.transparent,
                  Colors.blue.withOpacity(0.1 * _scanAnimation.value),
                ],
                stops: [
                  0.0,
                  _scanAnimation.value,
                  1.0,
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search,
                    size: 48,
                    color: Colors.blue.withOpacity(_scanAnimation.value),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scanning for Evidence...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.withOpacity(_scanAnimation.value),
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

  Widget _buildMagnifyingOverlay() {
    return AnimatedBuilder(
      animation: _magnifyAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: Transform.scale(
            scale: _magnifyAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.blue.withOpacity(0.5),
                  width: 2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _selectTool(String toolId) {
    setState(() {
      _selectedTool = toolId;
    });
    
    HapticFeedback.lightImpact();
    
    if (toolId == 'magnifying_glass') {
      _toggleMagnifying();
    } else {
      _useInvestigationTool(toolId);
    }
  }

  void _toggleMagnifying() {
    setState(() {
      _isMagnifying = !_isMagnifying;
    });
    
    if (_isMagnifying) {
      _magnifyController.forward();
    } else {
      _magnifyController.reverse();
    }
  }

  Future<void> _useInvestigationTool(String toolId) async {
    final context = {
      'content': widget.pageContent,
      'pageNumber': widget.pageNumber,
      'annotations': widget.annotations,
    };
    
    final result = await _investigationService.useInvestigationTool(toolId, context);
    
    if (result['success'] == true && mounted) {
      _showToolResults(toolId, result['results']);
    }
  }

  void _showToolResults(String toolId, Map<String, dynamic> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(_investigationService.tools[toolId]?.icon ?? '🔍'),
            const SizedBox(width: 8),
            Text(_investigationService.tools[toolId]?.name ?? 'Tool Results'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ...results.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(entry.value.toString()),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _selectClue(EvidenceClue clue) {
    setState(() {
      _selectedClue = clue;
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _collectEvidence(EvidenceClue clue) async {
    if (clue.isHidden) {
      _showHiddenEvidenceDialog(clue);
      return;
    }
    
    final success = await _investigationService.collectEvidence(
      clue.id,
      'Page ${widget.pageNumber}',
      widget.pageContent,
    );
    
    if (success) {
      _collectController.forward().then((_) {
        _collectController.reset();
      });
      
      setState(() {
        _detectedClues.removeWhere((c) => c.id == clue.id);
        _selectedClue = null;
      });
      
      HapticFeedback.heavyImpact();
      
      widget.onEvidenceCollected?.call();
      
      _showCollectionSuccessDialog(clue);
    } else {
      _showCollectionFailureDialog(clue);
    }
  }

  void _showHiddenEvidenceDialog(EvidenceClue clue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.red),
            SizedBox(width: 8),
            Text('Hidden Evidence'),
          ],
        ),
        content: Text(
          'This evidence is currently hidden. You may need to:\n\n'
          '• Progress further in your investigation\n'
          '• Unlock higher revelation levels\n'
          '• Collect related evidence first\n'
          '• Use specialized investigation tools',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  void _showCollectionSuccessDialog(EvidenceClue clue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Evidence Collected!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              clue.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(clue.description),
            const SizedBox(height: 16),
            Text(
              'Relevance: ${(clue.relevance * 100).toInt()}%',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Investigation'),
          ),
        ],
      ),
    );
  }

  void _showCollectionFailureDialog(EvidenceClue clue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.orange),
            SizedBox(width: 8),
            Text('Already Collected'),
          ],
        ),
        content: const Text('This evidence has already been added to your collection.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Color _getCharacterColor(String character) {
    switch (character) {
      case 'MB': return Colors.blue;
      case 'JR': return Colors.orange;
      case 'EW': return Colors.red;
      case 'SW': return Colors.green;
      case 'Detective Sharma': return Colors.purple;
      case 'Dr. Chambers': return Colors.teal;
      default: return Colors.grey;
    }
  }

  Color _getEvidenceColor(EvidenceRarity rarity) {
    switch (rarity) {
      case EvidenceRarity.common: return Colors.grey;
      case EvidenceRarity.uncommon: return Colors.green;
      case EvidenceRarity.rare: return Colors.blue;
      case EvidenceRarity.epic: return Colors.purple;
      case EvidenceRarity.legendary: return Colors.orange;
    }
  }

  IconData _getEvidenceIcon(EvidenceType type) {
    switch (type) {
      case EvidenceType.document: return Icons.description;
      case EvidenceType.audio: return Icons.audiotrack;
      case EvidenceType.visual: return Icons.image;
      case EvidenceType.physical: return Icons.thermostat;
      case EvidenceType.digital: return Icons.computer;
      case EvidenceType.official: return Icons.gavel;
      case EvidenceType.other: return Icons.help;
    }
  }
}

// Evidence clue data model
class EvidenceClue {
  final String id;
  final String title;
  final String description;
  final EvidenceType type;
  final Offset position;
  final EvidenceRarity rarity;
  final double relevance;
  final bool isHidden;

  EvidenceClue({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.position,
    required this.rarity,
    required this.relevance,
    required this.isHidden,
  });
}

enum EvidenceRarity { common, uncommon, rare, epic, legendary }