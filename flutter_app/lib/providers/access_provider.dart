import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AccessLevel {
  public,
  classified,
  restricted,
  topSecret,
}

class AccessProvider extends ChangeNotifier {
  Set<String> _unlockedContent = {};
  AccessLevel _currentLevel = AccessLevel.public;

  Set<String> get unlockedContent => Set.unmodifiable(_unlockedContent);
  AccessLevel get currentLevel => _currentLevel;

  bool isUnlocked(String key) {
    return _unlockedContent.contains(key);
  }

  Future<bool> unlockContent(String key, {AccessLevel? requiredLevel}) async {
    try {
      // For now, we'll simulate the unlock without payment
      // In the real implementation, this would include payment processing
      await _simulateUnlockProcess();

      _unlockedContent.add(key);
      
      if (requiredLevel != null && requiredLevel.index > _currentLevel.index) {
        _currentLevel = requiredLevel;
      }
      
      await _saveToStorage();
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('Unlock failed: $e');
      return false;
    }
  }

  Future<void> _simulateUnlockProcess() async {
    // Simulate processing time
    await Future.delayed(const Duration(seconds: 1));
    // In real implementation, this would handle payment processing
  }

  String getAccessLevelName(AccessLevel level) {
    switch (level) {
      case AccessLevel.public:
        return 'Public';
      case AccessLevel.classified:
        return 'Classified';
      case AccessLevel.restricted:
        return 'Restricted';
      case AccessLevel.topSecret:
        return 'Top Secret';
    }
  }

  String getAccessLevelPrice(AccessLevel level) {
    switch (level) {
      case AccessLevel.public:
        return 'Free';
      case AccessLevel.classified:
        return '£1.99';
      case AccessLevel.restricted:
        return '£2.99';
      case AccessLevel.topSecret:
        return '£4.99';
    }
  }

  Color getAccessLevelColor(AccessLevel level) {
    switch (level) {
      case AccessLevel.public:
        return const Color(0xFF4CAF50); // Green
      case AccessLevel.classified:
        return const Color(0xFFFF9800); // Orange
      case AccessLevel.restricted:
        return const Color(0xFFFF5722); // Deep Orange
      case AccessLevel.topSecret:
        return const Color(0xFFD32F2F); // Red
    }
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('unlocked_content', _unlockedContent.toList());
    await prefs.setInt('current_access_level', _currentLevel.index);
  }

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    final unlockedList = prefs.getStringList('unlocked_content');
    if (unlockedList != null) {
      _unlockedContent = unlockedList.toSet();
    }
    
    final levelIndex = prefs.getInt('current_access_level');
    if (levelIndex != null) {
      _currentLevel = AccessLevel.values[levelIndex];
    }
    
    notifyListeners();
  }

  // For development/testing purposes
  void unlockAllContent() {
    // This would unlock all available content for testing
    _currentLevel = AccessLevel.topSecret;
    _saveToStorage();
    notifyListeners();
  }

  void resetAccess() {
    _unlockedContent.clear();
    _currentLevel = AccessLevel.public;
    _saveToStorage();
    notifyListeners();
  }
}