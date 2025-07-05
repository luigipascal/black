import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/enhanced_document_models.dart';

class InvestigationService {
  static final InvestigationService _instance = InvestigationService._internal();
  factory InvestigationService() => _instance;
  InvestigationService._internal();

  // Investigation state
  Map<String, Evidence> _collectedEvidence = {};
  Map<String, Character> _characters = {};
  List<TimelineEvent> _timeline = [];
  Map<String, Connection> _connections = {};
  InvestigationProgress _progress = InvestigationProgress();
  
  // Theories and hypotheses
  List<Theory> _userTheories = [];
  Map<String, Hypothesis> _hypotheses = {};
  
  // Investigation tools
  Set<String> _unlockedTools = {'magnifying_glass'};
  Map<String, InvestigationTool> _tools = {};

  // Initialize the investigation system
  Future<void> initialize() async {
    await _loadInvestigationData();
    _initializeCharacters();
    _initializeTools();
    _initializeTimeline();
  }

  // Evidence Collection System
  Future<bool> collectEvidence(String evidenceId, String source, String pageContext) async {
    if (_collectedEvidence.containsKey(evidenceId)) {
      return false; // Already collected
    }

    final evidence = Evidence(
      id: evidenceId,
      title: _getEvidenceTitle(evidenceId),
      description: _getEvidenceDescription(evidenceId),
      type: _getEvidenceType(evidenceId),
      source: source,
      pageContext: pageContext,
      collectedAt: DateTime.now(),
      relevance: _calculateEvidenceRelevance(evidenceId),
      connections: _findEvidenceConnections(evidenceId),
    );

    _collectedEvidence[evidenceId] = evidence;
    _updateInvestigationProgress();
    _checkForNewConnections(evidence);
    await _saveInvestigationData();
    
    return true;
  }

  // Character relationship tracking
  void updateCharacterRelationship(String char1, String char2, RelationshipType type, double strength) {
    final connectionId = '${char1}_$char2';
    final connection = Connection(
      id: connectionId,
      fromCharacter: char1,
      toCharacter: char2,
      type: type,
      strength: strength,
      evidence: _findConnectionEvidence(char1, char2),
      discoveredAt: DateTime.now(),
    );

    _connections[connectionId] = connection;
    _updateCharacterConnections(char1, char2, connection);
  }

  // Timeline investigation
  void addTimelineEvent(TimelineEvent event) {
    _timeline.add(event);
    _timeline.sort((a, b) => a.date.compareTo(b.date));
    _checkTimelinePatterns();
  }

  // Theory and hypothesis system
  String createTheory(String title, String description, List<String> evidenceIds) {
    final theoryId = 'theory_${DateTime.now().millisecondsSinceEpoch}';
    final theory = Theory(
      id: theoryId,
      title: title,
      description: description,
      evidenceIds: evidenceIds,
      confidence: _calculateTheoryConfidence(evidenceIds),
      createdAt: DateTime.now(),
      status: TheoryStatus.active,
    );

    _userTheories.add(theory);
    _evaluateTheory(theory);
    return theoryId;
  }

  // Investigation tools
  bool unlockTool(String toolId) {
    if (_unlockedTools.contains(toolId)) return false;
    
    _unlockedTools.add(toolId);
    _tools[toolId]?.isUnlocked = true;
    return true;
  }

  Future<Map<String, dynamic>> useInvestigationTool(String toolId, Map<String, dynamic> context) async {
    if (!_unlockedTools.contains(toolId)) {
      return {'success': false, 'error': 'Tool not unlocked'};
    }

    final tool = _tools[toolId];
    if (tool == null) {
      return {'success': false, 'error': 'Tool not found'};
    }

    switch (toolId) {
      case 'magnifying_glass':
        return _useMagnifyingGlass(context);
      case 'thermal_camera':
        return _useThermalCamera(context);
      case 'audio_analyzer':
        return _useAudioAnalyzer(context);
      case 'timeline_mapper':
        return _useTimelineMapper(context);
      case 'relationship_analyzer':
        return _useRelationshipAnalyzer(context);
      case 'evidence_correlator':
        return _useEvidenceCorrelator(context);
      default:
        return {'success': false, 'error': 'Unknown tool'};
    }
  }

  // Investigation progress and insights
  InvestigationInsights getInvestigationInsights() {
    return InvestigationInsights(
      totalEvidence: _collectedEvidence.length,
      characterConnections: _connections.length,
      timelineEvents: _timeline.length,
      theories: _userTheories.length,
      completionPercentage: _calculateCompletionPercentage(),
      activeLeads: _getActiveLeads(),
      suggestedActions: _getSuggestedActions(),
      mysteryScore: _calculateMysteryScore(),
    );
  }

  // Mystery solving mechanics
  MysteryStatus checkMysteryStatus() {
    final criticalEvidence = _getCriticalEvidence();
    final keyConnections = _getKeyConnections();
    final timelineCoverage = _getTimelineCoverage();
    
    if (criticalEvidence >= 0.9 && keyConnections >= 0.8 && timelineCoverage >= 0.85) {
      return MysteryStatus.solved;
    } else if (criticalEvidence >= 0.6 || keyConnections >= 0.6) {
      return MysteryStatus.nearSolution;
    } else if (criticalEvidence >= 0.3 || keyConnections >= 0.3) {
      return MysteryStatus.investigating;
    } else {
      return MysteryStatus.beginning;
    }
  }

  // Getters for UI
  Map<String, Evidence> get collectedEvidence => Map.from(_collectedEvidence);
  Map<String, Character> get characters => Map.from(_characters);
  List<TimelineEvent> get timeline => List.from(_timeline);
  Map<String, Connection> get connections => Map.from(_connections);
  List<Theory> get userTheories => List.from(_userTheories);
  InvestigationProgress get progress => _progress;
  Set<String> get unlockedTools => Set.from(_unlockedTools);
  Map<String, InvestigationTool> get tools => Map.from(_tools);

  // Private helper methods
  void _initializeCharacters() {
    _characters = {
      'MB': Character(
        id: 'MB',
        name: 'Margaret Blackthorn',
        role: CharacterRole.family,
        status: CharacterStatus.missing,
        firstAppearance: DateTime(1963),
        lastSeen: DateTime(1963, 12, 15),
        connections: [],
        evidence: [],
        suspicionLevel: 0.3,
        reliability: 0.8,
      ),
      'JR': Character(
        id: 'JR',
        name: 'James Reed',
        role: CharacterRole.investigator,
        status: CharacterStatus.missing,
        firstAppearance: DateTime(1989),
        lastSeen: DateTime(1989, 3, 22),
        connections: [],
        evidence: [],
        suspicionLevel: 0.1,
        reliability: 0.9,
      ),
      'EW': Character(
        id: 'EW',
        name: 'Eliza Winston',
        role: CharacterRole.engineer,
        status: CharacterStatus.active,
        firstAppearance: DateTime(1995),
        lastSeen: DateTime(2024),
        connections: [],
        evidence: [],
        suspicionLevel: 0.2,
        reliability: 0.85,
      ),
      'SW': Character(
        id: 'SW',
        name: 'Simon Wells',
        role: CharacterRole.investigator,
        status: CharacterStatus.active,
        firstAppearance: DateTime(2024),
        lastSeen: DateTime(2024),
        connections: [],
        evidence: [],
        suspicionLevel: 0.4,
        reliability: 0.7,
      ),
      'Detective Sharma': Character(
        id: 'Detective Sharma',
        name: 'Detective Sharma',
        role: CharacterRole.law_enforcement,
        status: CharacterStatus.active,
        firstAppearance: DateTime(2020),
        lastSeen: DateTime(2024),
        connections: [],
        evidence: [],
        suspicionLevel: 0.1,
        reliability: 0.95,
      ),
      'Dr. Chambers': Character(
        id: 'Dr. Chambers',
        name: 'Dr. Chambers',
        role: CharacterRole.expert,
        status: CharacterStatus.active,
        firstAppearance: DateTime(2022),
        lastSeen: DateTime(2024),
        connections: [],
        evidence: [],
        suspicionLevel: 0.05,
        reliability: 0.9,
      ),
    };
  }

  void _initializeTools() {
    _tools = {
      'magnifying_glass': InvestigationTool(
        id: 'magnifying_glass',
        name: 'Magnifying Glass',
        description: 'Examine text and annotations for hidden details',
        icon: '🔍',
        isUnlocked: true,
        usageCount: 0,
      ),
      'thermal_camera': InvestigationTool(
        id: 'thermal_camera',
        name: 'Thermal Camera',
        description: 'Detect temperature anomalies in the manor',
        icon: '📷',
        isUnlocked: false,
        usageCount: 0,
      ),
      'audio_analyzer': InvestigationTool(
        id: 'audio_analyzer',
        name: 'Audio Analyzer',
        description: 'Analyze mysterious sounds and recordings',
        icon: '🎧',
        isUnlocked: false,
        usageCount: 0,
      ),
      'timeline_mapper': InvestigationTool(
        id: 'timeline_mapper',
        name: 'Timeline Mapper',
        description: 'Map events across time to find patterns',
        icon: '⏰',
        isUnlocked: false,
        usageCount: 0,
      ),
      'relationship_analyzer': InvestigationTool(
        id: 'relationship_analyzer',
        name: 'Relationship Analyzer',
        description: 'Analyze connections between characters',
        icon: '🕸️',
        isUnlocked: false,
        usageCount: 0,
      ),
      'evidence_correlator': InvestigationTool(
        id: 'evidence_correlator',
        name: 'Evidence Correlator',
        description: 'Find hidden connections between evidence',
        icon: '🔗',
        isUnlocked: false,
        usageCount: 0,
      ),
    };
  }

  void _initializeTimeline() {
    _timeline = [
      TimelineEvent(
        id: 'manor_built',
        title: 'Blackthorn Manor Built',
        description: 'Cornelius Blackthorn constructs the Gothic Revival manor',
        date: DateTime(1847),
        type: EventType.construction,
        importance: EventImportance.high,
        characters: [],
        evidence: [],
      ),
      TimelineEvent(
        id: 'finch_survey',
        title: 'Professor Finch\'s Survey',
        description: 'Harold Finch conducts architectural survey',
        date: DateTime(1963, 8, 15),
        type: EventType.investigation,
        importance: EventImportance.high,
        characters: ['Harold Finch'],
        evidence: ['finch_notes', 'architectural_drawings'],
      ),
      TimelineEvent(
        id: 'margaret_concerns',
        title: 'Margaret\'s Growing Concerns',
        description: 'Margaret Blackthorn notes unusual activity',
        date: DateTime(1963, 10, 1),
        type: EventType.observation,
        importance: EventImportance.medium,
        characters: ['MB'],
        evidence: ['margaret_diary'],
      ),
    ];
  }

  String _getEvidenceTitle(String evidenceId) {
    final titles = {
      'thermal_anomaly_east': 'Thermal Anomaly - East Wing',
      'margaret_diary_1963': 'Margaret\'s Diary Entry - October 1963',
      'finch_notes': 'Professor Finch\'s Survey Notes',
      'architectural_drawings': 'Original Architectural Drawings',
      'audio_recording_basement': 'Mysterious Audio - Basement',
      'temperature_readings': 'Temperature Measurement Data',
      'missing_persons_report': 'Missing Persons Report - James Reed',
      'family_portrait': 'Blackthorn Family Portrait',
      'foundation_documents': 'Manor Foundation Documents',
      'witness_statement_groundskeeper': 'Groundskeeper Witness Statement',
    };
    return titles[evidenceId] ?? 'Unknown Evidence';
  }

  String _getEvidenceDescription(String evidenceId) {
    final descriptions = {
      'thermal_anomaly_east': 'Consistent cold spot in the east wing foundation, temperature 15°F below ambient',
      'margaret_diary_1963': 'Personal diary entry describing strange sounds and sensations in the manor',
      'finch_notes': 'Detailed architectural survey notes with observations about structural anomalies',
      'architectural_drawings': 'Original 1847 blueprints showing hidden rooms and passages',
      'audio_recording_basement': '47-second recording of unexplained sounds from the basement level',
      'temperature_readings': 'Systematic temperature measurements showing localized cold spots',
      'missing_persons_report': 'Official police report on James Reed\'s disappearance in March 1989',
      'family_portrait': '1920s family portrait with mysterious figure in background',
      'foundation_documents': 'Legal documents from manor construction revealing unusual specifications',
      'witness_statement_groundskeeper': 'Testimony from manor groundskeeper about unusual occurrences',
    };
    return descriptions[evidenceId] ?? 'No description available';
  }

  EvidenceType _getEvidenceType(String evidenceId) {
    if (evidenceId.contains('audio')) return EvidenceType.audio;
    if (evidenceId.contains('thermal') || evidenceId.contains('temperature')) return EvidenceType.physical;
    if (evidenceId.contains('diary') || evidenceId.contains('notes') || evidenceId.contains('statement')) return EvidenceType.document;
    if (evidenceId.contains('portrait') || evidenceId.contains('drawing')) return EvidenceType.visual;
    if (evidenceId.contains('report') || evidenceId.contains('documents')) return EvidenceType.official;
    return EvidenceType.other;
  }

  double _calculateEvidenceRelevance(String evidenceId) {
    final relevanceMap = {
      'thermal_anomaly_east': 0.9,
      'margaret_diary_1963': 0.8,
      'finch_notes': 0.85,
      'architectural_drawings': 0.95,
      'audio_recording_basement': 0.9,
      'temperature_readings': 0.7,
      'missing_persons_report': 0.95,
      'family_portrait': 0.6,
      'foundation_documents': 0.8,
      'witness_statement_groundskeeper': 0.75,
    };
    return relevanceMap[evidenceId] ?? 0.5;
  }

  List<String> _findEvidenceConnections(String evidenceId) {
    final connections = <String, List<String>>{
      'thermal_anomaly_east': ['temperature_readings', 'finch_notes'],
      'margaret_diary_1963': ['audio_recording_basement', 'witness_statement_groundskeeper'],
      'finch_notes': ['architectural_drawings', 'thermal_anomaly_east'],
      'architectural_drawings': ['foundation_documents', 'finch_notes'],
      'missing_persons_report': ['margaret_diary_1963', 'audio_recording_basement'],
    };
    return connections[evidenceId] ?? [];
  }

  void _updateInvestigationProgress() {
    _progress.totalEvidence = _collectedEvidence.length;
    _progress.criticalEvidence = _collectedEvidence.values.where((e) => e.relevance > 0.8).length;
    _progress.investigationLevel = _calculateInvestigationLevel();
    _progress.lastUpdated = DateTime.now();
  }

  InvestigationLevel _calculateInvestigationLevel() {
    final evidenceCount = _collectedEvidence.length;
    final connectionCount = _connections.length;
    
    if (evidenceCount >= 25 && connectionCount >= 15) return InvestigationLevel.expert;
    if (evidenceCount >= 15 && connectionCount >= 8) return InvestigationLevel.experienced;
    if (evidenceCount >= 8 && connectionCount >= 4) return InvestigationLevel.intermediate;
    if (evidenceCount >= 3) return InvestigationLevel.novice;
    return InvestigationLevel.beginner;
  }

  void _checkForNewConnections(Evidence evidence) {
    for (final connectionId in evidence.connections) {
      if (_collectedEvidence.containsKey(connectionId)) {
        // Create automatic connection between evidences
        final connectionKey = '${evidence.id}_$connectionId';
        if (!_connections.containsKey(connectionKey)) {
          _connections[connectionKey] = Connection(
            id: connectionKey,
            fromCharacter: evidence.id,
            toCharacter: connectionId,
            type: RelationshipType.evidence_link,
            strength: 0.7,
            evidence: [evidence.id, connectionId],
            discoveredAt: DateTime.now(),
          );
        }
      }
    }
  }

  double _calculateTheoryConfidence(List<String> evidenceIds) {
    if (evidenceIds.isEmpty) return 0.0;
    
    double totalRelevance = 0.0;
    int validEvidence = 0;
    
    for (final evidenceId in evidenceIds) {
      final evidence = _collectedEvidence[evidenceId];
      if (evidence != null) {
        totalRelevance += evidence.relevance;
        validEvidence++;
      }
    }
    
    return validEvidence > 0 ? (totalRelevance / validEvidence) : 0.0;
  }

  void _evaluateTheory(Theory theory) {
    // Check if theory matches known patterns or solutions
    if (theory.confidence > 0.8 && theory.evidenceIds.length >= 5) {
      theory.status = TheoryStatus.promising;
    } else if (theory.confidence < 0.3) {
      theory.status = TheoryStatus.weak;
    }
  }

  // Investigation tool implementations
  Map<String, dynamic> _useMagnifyingGlass(Map<String, dynamic> context) {
    final pageContent = context['content'] as String? ?? '';
    final hiddenClues = _findHiddenClues(pageContent);
    
    return {
      'success': true,
      'tool': 'magnifying_glass',
      'results': {
        'hiddenClues': hiddenClues,
        'detailLevel': 'enhanced',
        'newEvidence': hiddenClues.isNotEmpty,
      }
    };
  }

  Map<String, dynamic> _useThermalCamera(Map<String, dynamic> context) {
    final location = context['location'] as String? ?? '';
    final thermalData = _generateThermalData(location);
    
    return {
      'success': true,
      'tool': 'thermal_camera',
      'results': {
        'thermalReadings': thermalData,
        'anomalies': thermalData['anomalies'],
        'temperature': thermalData['avgTemp'],
      }
    };
  }

  Map<String, dynamic> _useAudioAnalyzer(Map<String, dynamic> context) {
    final audioFile = context['audioFile'] as String? ?? '';
    final analysis = _analyzeAudio(audioFile);
    
    return {
      'success': true,
      'tool': 'audio_analyzer',
      'results': analysis,
    };
  }

  Map<String, dynamic> _useTimelineMapper(Map<String, dynamic> context) {
    final timeRange = context['timeRange'] as Map<String, dynamic>?;
    final events = _getEventsInRange(timeRange);
    
    return {
      'success': true,
      'tool': 'timeline_mapper',
      'results': {
        'events': events,
        'patterns': _findTimelinePatterns(),
        'gaps': _findTimelineGaps(),
      }
    };
  }

  Map<String, dynamic> _useRelationshipAnalyzer(Map<String, dynamic> context) {
    final characterId = context['characterId'] as String?;
    final relationships = _analyzeCharacterRelationships(characterId);
    
    return {
      'success': true,
      'tool': 'relationship_analyzer',
      'results': relationships,
    };
  }

  Map<String, dynamic> _useEvidenceCorrelator(Map<String, dynamic> context) {
    final evidenceId = context['evidenceId'] as String?;
    final correlations = _findEvidenceCorrelations(evidenceId);
    
    return {
      'success': true,
      'tool': 'evidence_correlator',
      'results': correlations,
    };
  }

  List<String> _findHiddenClues(String content) {
    final clues = <String>[];
    
    // Look for hidden patterns in text
    if (content.contains('█')) {
      clues.add('Redacted text detected - may contain hidden information');
    }
    
    if (RegExp(r'\b\d{4}\b').hasMatch(content)) {
      clues.add('Date references found - check timeline significance');
    }
    
    if (content.toLowerCase().contains('cold') || content.toLowerCase().contains('temperature')) {
      clues.add('Temperature reference - potential thermal anomaly connection');
    }
    
    return clues;
  }

  Map<String, dynamic> _generateThermalData(String location) {
    final random = math.Random();
    final baseTemp = 68.0 + random.nextDouble() * 10;
    final anomalies = <Map<String, dynamic>>[];
    
    if (location.toLowerCase().contains('east')) {
      anomalies.add({
        'type': 'cold_spot',
        'temperature': baseTemp - 15,
        'location': 'Foundation area',
        'significance': 'high'
      });
    }
    
    return {
      'avgTemp': baseTemp,
      'anomalies': anomalies,
      'readings': List.generate(10, (i) => baseTemp + random.nextDouble() * 5 - 2.5),
    };
  }

  Map<String, dynamic> _analyzeAudio(String audioFile) {
    return {
      'duration': '47 seconds',
      'frequency_analysis': {
        'dominant_frequency': '127 Hz',
        'unusual_patterns': true,
        'voice_detected': false,
      },
      'anomalies': [
        'Subsonic vibrations detected',
        'Periodic oscillations every 7.3 seconds',
        'Background electromagnetic interference'
      ],
      'confidence': 0.85,
    };
  }

  List<Map<String, dynamic>> _getEventsInRange(Map<String, dynamic>? timeRange) {
    if (timeRange == null) return [];
    
    return _timeline.map((event) => {
      'id': event.id,
      'title': event.title,
      'date': event.date.toIso8601String(),
      'type': event.type.toString(),
      'importance': event.importance.toString(),
    }).toList();
  }

  List<String> _findTimelinePatterns() {
    return [
      'Missing persons incidents occur every 26 years',
      'Thermal anomalies increase during winter months',
      'Family members report activity in 10-year cycles'
    ];
  }

  List<String> _findTimelineGaps() {
    return [
      '1870-1900: No recorded incidents (30-year gap)',
      '1990-2020: Limited documentation period',
      '2010-2015: Suspicious lack of maintenance records'
    ];
  }

  Map<String, dynamic> _analyzeCharacterRelationships(String? characterId) {
    if (characterId == null) return {};
    
    final character = _characters[characterId];
    if (character == null) return {};
    
    return {
      'character': character.name,
      'connections': character.connections.length,
      'suspicion_level': character.suspicionLevel,
      'reliability': character.reliability,
      'status': character.status.toString(),
      'related_evidence': character.evidence.length,
    };
  }

  Map<String, dynamic> _findEvidenceCorrelations(String? evidenceId) {
    if (evidenceId == null) return {};
    
    final evidence = _collectedEvidence[evidenceId];
    if (evidence == null) return {};
    
    return {
      'evidence': evidence.title,
      'correlations': evidence.connections.length,
      'relevance': evidence.relevance,
      'type': evidence.type.toString(),
      'connected_evidence': evidence.connections,
    };
  }

  void _updateCharacterConnections(String char1, String char2, Connection connection) {
    _characters[char1]?.connections.add(connection.id);
    _characters[char2]?.connections.add(connection.id);
  }

  void _checkTimelinePatterns() {
    // Analyze timeline for patterns and update insights
  }

  double _calculateCompletionPercentage() {
    const totalPossibleEvidence = 50;
    const totalPossibleConnections = 30;
    
    final evidenceCompletion = (_collectedEvidence.length / totalPossibleEvidence).clamp(0.0, 1.0);
    final connectionCompletion = (_connections.length / totalPossibleConnections).clamp(0.0, 1.0);
    
    return ((evidenceCompletion + connectionCompletion) / 2) * 100;
  }

  List<String> _getActiveLeads() {
    final leads = <String>[];
    
    if (_collectedEvidence.length < 5) {
      leads.add('Examine annotations more carefully for hidden evidence');
    }
    
    if (_connections.length < 3) {
      leads.add('Investigate character relationships using the relationship analyzer');
    }
    
    if (!_unlockedTools.contains('thermal_camera') && _collectedEvidence.containsKey('thermal_anomaly_east')) {
      leads.add('Unlock thermal camera to investigate temperature anomalies');
    }
    
    return leads;
  }

  List<String> _getSuggestedActions() {
    final actions = <String>[];
    
    if (_userTheories.isEmpty) {
      actions.add('Create your first theory based on collected evidence');
    }
    
    if (_timeline.length < 10) {
      actions.add('Use timeline mapper to discover more historical events');
    }
    
    final mysteryStatus = checkMysteryStatus();
    if (mysteryStatus == MysteryStatus.nearSolution) {
      actions.add('Review all evidence - you\'re close to solving the mystery!');
    }
    
    return actions;
  }

  double _calculateMysteryScore() {
    final evidenceScore = (_collectedEvidence.length / 50.0) * 40;
    final connectionScore = (_connections.length / 30.0) * 30;
    final theoryScore = (_userTheories.length / 10.0) * 20;
    final toolScore = (_unlockedTools.length / 6.0) * 10;
    
    return (evidenceScore + connectionScore + theoryScore + toolScore).clamp(0.0, 100.0);
  }

  double _getCriticalEvidence() {
    final criticalCount = _collectedEvidence.values.where((e) => e.relevance > 0.8).length;
    return (criticalCount / 15.0).clamp(0.0, 1.0); // Assuming 15 critical pieces
  }

  double _getKeyConnections() {
    final keyCount = _connections.values.where((c) => c.strength > 0.7).length;
    return (keyCount / 20.0).clamp(0.0, 1.0); // Assuming 20 key connections
  }

  double _getTimelineCoverage() {
    return (_timeline.length / 50.0).clamp(0.0, 1.0); // Assuming 50 total events
  }

  // Data persistence
  Future<void> _loadInvestigationData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load evidence
    final evidenceJson = prefs.getString('investigation_evidence');
    if (evidenceJson != null) {
      final evidenceData = json.decode(evidenceJson) as Map<String, dynamic>;
      _collectedEvidence = evidenceData.map((key, value) =>
          MapEntry(key, Evidence.fromJson(value)));
    }
    
    // Load connections
    final connectionsJson = prefs.getString('investigation_connections');
    if (connectionsJson != null) {
      final connectionsData = json.decode(connectionsJson) as Map<String, dynamic>;
      _connections = connectionsData.map((key, value) =>
          MapEntry(key, Connection.fromJson(value)));
    }
    
    // Load theories
    final theoriesJson = prefs.getString('investigation_theories');
    if (theoriesJson != null) {
      final theoriesList = json.decode(theoriesJson) as List;
      _userTheories = theoriesList.map((theory) => Theory.fromJson(theory)).toList();
    }
    
    // Load unlocked tools
    final toolsJson = prefs.getString('investigation_tools');
    if (toolsJson != null) {
      final toolsList = json.decode(toolsJson) as List;
      _unlockedTools = Set.from(toolsList);
    }
  }

  Future<void> _saveInvestigationData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save evidence
    final evidenceData = _collectedEvidence.map((key, value) =>
        MapEntry(key, value.toJson()));
    await prefs.setString('investigation_evidence', json.encode(evidenceData));
    
    // Save connections
    final connectionsData = _connections.map((key, value) =>
        MapEntry(key, value.toJson()));
    await prefs.setString('investigation_connections', json.encode(connectionsData));
    
    // Save theories
    final theoriesList = _userTheories.map((theory) => theory.toJson()).toList();
    await prefs.setString('investigation_theories', json.encode(theoriesList));
    
    // Save unlocked tools
    await prefs.setString('investigation_tools', json.encode(_unlockedTools.toList()));
  }
}

// Data models for investigation system
class Evidence {
  final String id;
  final String title;
  final String description;
  final EvidenceType type;
  final String source;
  final String pageContext;
  final DateTime collectedAt;
  final double relevance;
  final List<String> connections;

  Evidence({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.source,
    required this.pageContext,
    required this.collectedAt,
    required this.relevance,
    required this.connections,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type.index,
    'source': source,
    'pageContext': pageContext,
    'collectedAt': collectedAt.toIso8601String(),
    'relevance': relevance,
    'connections': connections,
  };

  factory Evidence.fromJson(Map<String, dynamic> json) => Evidence(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    type: EvidenceType.values[json['type']],
    source: json['source'],
    pageContext: json['pageContext'],
    collectedAt: DateTime.parse(json['collectedAt']),
    relevance: json['relevance'].toDouble(),
    connections: List<String>.from(json['connections']),
  );
}

class Character {
  final String id;
  final String name;
  final CharacterRole role;
  CharacterStatus status;
  final DateTime firstAppearance;
  DateTime lastSeen;
  List<String> connections;
  List<String> evidence;
  double suspicionLevel;
  double reliability;

  Character({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    required this.firstAppearance,
    required this.lastSeen,
    required this.connections,
    required this.evidence,
    required this.suspicionLevel,
    required this.reliability,
  });
}

class TimelineEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final EventType type;
  final EventImportance importance;
  final List<String> characters;
  final List<String> evidence;

  TimelineEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    required this.importance,
    required this.characters,
    required this.evidence,
  });
}

class Connection {
  final String id;
  final String fromCharacter;
  final String toCharacter;
  final RelationshipType type;
  final double strength;
  final List<String> evidence;
  final DateTime discoveredAt;

  Connection({
    required this.id,
    required this.fromCharacter,
    required this.toCharacter,
    required this.type,
    required this.strength,
    required this.evidence,
    required this.discoveredAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromCharacter': fromCharacter,
    'toCharacter': toCharacter,
    'type': type.index,
    'strength': strength,
    'evidence': evidence,
    'discoveredAt': discoveredAt.toIso8601String(),
  };

  factory Connection.fromJson(Map<String, dynamic> json) => Connection(
    id: json['id'],
    fromCharacter: json['fromCharacter'],
    toCharacter: json['toCharacter'],
    type: RelationshipType.values[json['type']],
    strength: json['strength'].toDouble(),
    evidence: List<String>.from(json['evidence']),
    discoveredAt: DateTime.parse(json['discoveredAt']),
  );
}

class Theory {
  final String id;
  final String title;
  final String description;
  final List<String> evidenceIds;
  double confidence;
  final DateTime createdAt;
  TheoryStatus status;

  Theory({
    required this.id,
    required this.title,
    required this.description,
    required this.evidenceIds,
    required this.confidence,
    required this.createdAt,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'evidenceIds': evidenceIds,
    'confidence': confidence,
    'createdAt': createdAt.toIso8601String(),
    'status': status.index,
  };

  factory Theory.fromJson(Map<String, dynamic> json) => Theory(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    evidenceIds: List<String>.from(json['evidenceIds']),
    confidence: json['confidence'].toDouble(),
    createdAt: DateTime.parse(json['createdAt']),
    status: TheoryStatus.values[json['status']],
  );
}

class InvestigationTool {
  final String id;
  final String name;
  final String description;
  final String icon;
  bool isUnlocked;
  int usageCount;

  InvestigationTool({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    required this.usageCount,
  });
}

class InvestigationProgress {
  int totalEvidence = 0;
  int criticalEvidence = 0;
  InvestigationLevel investigationLevel = InvestigationLevel.beginner;
  DateTime lastUpdated = DateTime.now();

  InvestigationProgress();
}

class InvestigationInsights {
  final int totalEvidence;
  final int characterConnections;
  final int timelineEvents;
  final int theories;
  final double completionPercentage;
  final List<String> activeLeads;
  final List<String> suggestedActions;
  final double mysteryScore;

  InvestigationInsights({
    required this.totalEvidence,
    required this.characterConnections,
    required this.timelineEvents,
    required this.theories,
    required this.completionPercentage,
    required this.activeLeads,
    required this.suggestedActions,
    required this.mysteryScore,
  });
}

class Hypothesis {
  final String id;
  final String title;
  final String description;
  final double probability;
  final List<String> supportingEvidence;
  final List<String> contradictingEvidence;

  Hypothesis({
    required this.id,
    required this.title,
    required this.description,
    required this.probability,
    required this.supportingEvidence,
    required this.contradictingEvidence,
  });
}

// Enums
enum EvidenceType { document, audio, visual, physical, digital, official, other }
enum CharacterRole { family, investigator, engineer, law_enforcement, expert, witness, other }
enum CharacterStatus { active, missing, deceased, unknown }
enum RelationshipType { family, professional, friend, enemy, evidence_link, timeline_link }
enum EventType { construction, investigation, observation, incident, discovery, disappearance }
enum EventImportance { low, medium, high, critical }
enum TheoryStatus { active, promising, weak, disproven, confirmed }
enum InvestigationLevel { beginner, novice, intermediate, experienced, expert }
enum MysteryStatus { beginning, investigating, nearSolution, solved }