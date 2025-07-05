import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/document_models.dart';

class DocumentState extends ChangeNotifier {
  int _currentPage = 0;
  ReadingMode _readingMode = ReadingMode.singlePage;
  Map<String, Offset> _annotationPositions = {};
  Set<String> _unlockedContent = {};
  double _zoomLevel = 1.0;
  Offset _panOffset = Offset.zero;

  // Getters
  int get currentPage => _currentPage;
  ReadingMode get readingMode => _readingMode;
  Map<String, Offset> get annotationPositions => Map.unmodifiable(_annotationPositions);
  Set<String> get unlockedContent => Set.unmodifiable(_unlockedContent);
  double get zoomLevel => _zoomLevel;
  Offset get panOffset => _panOffset;

  // Page navigation
  void setCurrentPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  void nextPage() {
    _currentPage++;
    notifyListeners();
  }

  void previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      notifyListeners();
    }
  }

  // Reading mode management
  void setReadingMode(ReadingMode mode) {
    _readingMode = mode;
    _saveToStorage();
    notifyListeners();
  }

  void toggleReadingMode() {
    _readingMode = _readingMode == ReadingMode.singlePage
        ? ReadingMode.bookSpread
        : ReadingMode.singlePage;
    _saveToStorage();
    notifyListeners();
  }

  // Annotation position management
  void updateAnnotationPosition(String id, Offset position) {
    _annotationPositions[id] = position;
    _saveToStorage();
    notifyListeners();
  }

  Offset? getAnnotationPosition(String id) {
    return _annotationPositions[id];
  }

  // Content unlocking
  void unlockContent(String contentId) {
    _unlockedContent.add(contentId);
    _saveToStorage();
    notifyListeners();
  }

  bool isContentUnlocked(String contentId) {
    return _unlockedContent.contains(contentId);
  }

  // Zoom and pan
  void setZoomLevel(double zoom) {
    _zoomLevel = zoom.clamp(0.5, 3.0);
    notifyListeners();
  }

  void setPanOffset(Offset offset) {
    _panOffset = offset;
    notifyListeners();
  }

  void resetZoomAndPan() {
    _zoomLevel = 1.0;
    _panOffset = Offset.zero;
    notifyListeners();
  }

  // Persistence
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();

    // Save annotation positions
    final positionsJson = _annotationPositions.map(
      (key, value) => MapEntry(key, {'x': value.dx, 'y': value.dy}),
    );
    await prefs.setString('annotation_positions', jsonEncode(positionsJson));

    // Save unlocked content
    await prefs.setStringList('unlocked_content', _unlockedContent.toList());

    // Save reading mode
    await prefs.setInt('reading_mode', _readingMode.index);

    // Save current page
    await prefs.setInt('current_page', _currentPage);
  }

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

    // Load annotation positions
    final positionsString = prefs.getString('annotation_positions');
    if (positionsString != null) {
      final positionsJson = jsonDecode(positionsString) as Map<String, dynamic>;
      _annotationPositions = positionsJson.map(
        (key, value) => MapEntry(key, Offset(value['x'], value['y'])),
      );
    }

    // Load unlocked content
    final unlockedList = prefs.getStringList('unlocked_content');
    if (unlockedList != null) {
      _unlockedContent = unlockedList.toSet();
    }

    // Load reading mode
    final readingModeIndex = prefs.getInt('reading_mode');
    if (readingModeIndex != null) {
      _readingMode = ReadingMode.values[readingModeIndex];
    }

    // Load current page
    final currentPage = prefs.getInt('current_page');
    if (currentPage != null) {
      _currentPage = currentPage;
    }

    notifyListeners();
  }

  // Reset all data (for testing or debugging)
  Future<void> resetAll() async {
    _currentPage = 0;
    _readingMode = ReadingMode.singlePage;
    _annotationPositions.clear();
    _unlockedContent.clear();
    _zoomLevel = 1.0;
    _panOffset = Offset.zero;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }
}