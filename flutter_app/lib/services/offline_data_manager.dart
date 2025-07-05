import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

import '../models/enhanced_document_models.dart';

class OfflineDataManager {
  static const String _dbName = 'blackthorn_manor_offline.db';
  static const int _dbVersion = 1;
  
  static OfflineDataManager? _instance;
  Database? _database;
  
  OfflineDataManager._internal();
  
  static OfflineDataManager get instance {
    _instance ??= OfflineDataManager._internal();
    return _instance!;
  }
  
  // Initialize offline database
  Future<void> initialize() async {
    if (_database != null) return;
    
    try {
      final dbPath = await getDatabasesPath();
      final fullPath = path.join(dbPath, _dbName);
      
      _database = await openDatabase(
        fullPath,
        version: _dbVersion,
        onCreate: _createDatabase,
        onUpgrade: _upgradeDatabase,
      );
      
      debugPrint('Offline database initialized at: $fullPath');
    } catch (e) {
      debugPrint('Failed to initialize offline database: $e');
      rethrow;
    }
  }
  
  // Create database tables
  Future<void> _createDatabase(Database db, int version) async {
    // Content table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS content (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        page_index INTEGER NOT NULL,
        content_type TEXT NOT NULL,
        title TEXT,
        content TEXT NOT NULL,
        metadata TEXT,
        last_updated INTEGER NOT NULL,
        is_synced INTEGER DEFAULT 0
      )
    ''');
    
    // Annotations table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS annotations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        page_index INTEGER NOT NULL,
        content_type TEXT NOT NULL,
        content TEXT NOT NULL,
        selected_text TEXT,
        position TEXT,
        styling TEXT,
        character_initials TEXT,
        annotation_type TEXT,
        revelation_level INTEGER DEFAULT 1,
        is_public INTEGER DEFAULT 0,
        is_collaborative INTEGER DEFAULT 0,
        user_id INTEGER,
        metadata TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        is_synced INTEGER DEFAULT 0
      )
    ''');
    
    // User progress table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        current_page INTEGER DEFAULT 0,
        revelation_level INTEGER DEFAULT 1,
        characters_discovered TEXT,
        bookmarks TEXT,
        reading_time INTEGER DEFAULT 0,
        last_updated INTEGER NOT NULL,
        is_synced INTEGER DEFAULT 0
      )
    ''');
    
    // Reading sessions table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reading_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        pages_viewed TEXT,
        annotations_created INTEGER DEFAULT 0,
        total_time INTEGER DEFAULT 0,
        is_synced INTEGER DEFAULT 0
      )
    ''');
    
    // Cached assets table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_assets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        asset_type TEXT NOT NULL,
        asset_key TEXT NOT NULL,
        file_path TEXT NOT NULL,
        size INTEGER NOT NULL,
        last_accessed INTEGER NOT NULL,
        expires_at INTEGER
      )
    ''');
    
    // Create indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_content_page ON content(page_index)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_annotations_page ON annotations(page_index)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_annotations_user ON annotations(user_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_progress_user ON user_progress(user_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_assets_key ON cached_assets(asset_key)');
  }
  
  // Upgrade database schema
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades if needed
    if (oldVersion < newVersion) {
      // Add upgrade logic here for future versions
    }
  }
  
  // Store content for offline access
  Future<void> cacheContent(List<EnhancedDocumentPage> pages) async {
    await initialize();
    final db = _database!;
    
    final batch = db.batch();
    
    for (final page in pages) {
      batch.insert(
        'content',
        {
          'page_index': page.pageIndex,
          'content_type': 'page',
          'title': page.title,
          'content': page.content,
          'metadata': json.encode({
            'section': page.section,
            'subsection': page.subsection,
            'wordCount': page.wordCount,
          }),
          'last_updated': DateTime.now().millisecondsSinceEpoch,
          'is_synced': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // Cache annotations
      for (final annotation in page.annotations) {
        batch.insert(
          'annotations',
          {
            'server_id': annotation.id.hashCode,
            'page_index': page.pageIndex,
            'content_type': annotation.type.toString(),
            'content': annotation.content,
            'selected_text': annotation.selectedText,
            'position': json.encode(annotation.position),
            'styling': json.encode(annotation.styling),
            'character_initials': annotation.characterInitials,
            'annotation_type': annotation.isFixed ? 'fixed' : 'draggable',
            'revelation_level': annotation.minRevelationLevel,
            'is_public': annotation.isCollaborative ? 1 : 0,
            'is_collaborative': annotation.isCollaborative ? 1 : 0,
            'user_id': 0, // Local user
            'metadata': json.encode(annotation.metadata),
            'created_at': annotation.timestamp.millisecondsSinceEpoch,
            'updated_at': annotation.timestamp.millisecondsSinceEpoch,
            'is_synced': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
    
    await batch.commit();
    debugPrint('Cached ${pages.length} pages and their annotations');
  }
  
  // Get cached content
  Future<List<EnhancedDocumentPage>> getCachedContent() async {
    await initialize();
    final db = _database!;
    
    final contentResults = await db.query(
      'content',
      where: 'content_type = ?',
      whereArgs: ['page'],
      orderBy: 'page_index ASC',
    );
    
    final pages = <EnhancedDocumentPage>[];
    
    for (final contentRow in contentResults) {
      final pageIndex = contentRow['page_index'] as int;
      
      // Get annotations for this page
      final annotationResults = await db.query(
        'annotations',
        where: 'page_index = ?',
        whereArgs: [pageIndex],
      );
      
      final annotations = annotationResults.map((row) {
        return EnhancedAnnotation(
          id: 'offline_${row['id']}',
          type: AnnotationType.note, // Default type
          content: row['content'] as String,
          selectedText: row['selected_text'] as String?,
          position: json.decode(row['position'] as String? ?? '{}'),
          styling: json.decode(row['styling'] as String? ?? '{}'),
          characterInitials: row['character_initials'] as String?,
          timestamp: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
          isFixed: (row['annotation_type'] as String) == 'fixed',
          minRevelationLevel: row['revelation_level'] as int,
          isCollaborative: (row['is_collaborative'] as int) == 1,
          metadata: json.decode(row['metadata'] as String? ?? '{}'),
        );
      }).toList();
      
      final metadata = json.decode(contentRow['metadata'] as String? ?? '{}');
      
      pages.add(EnhancedDocumentPage(
        pageIndex: pageIndex,
        title: contentRow['title'] as String? ?? 'Page ${pageIndex + 1}',
        content: contentRow['content'] as String,
        section: metadata['section'] as String?,
        subsection: metadata['subsection'] as String?,
        wordCount: metadata['wordCount'] as int? ?? 0,
        annotations: annotations,
      ));
    }
    
    debugPrint('Retrieved ${pages.length} cached pages');
    return pages;
  }
  
  // Cache user progress
  Future<void> cacheUserProgress(UserProgress progress) async {
    await initialize();
    final db = _database!;
    
    await db.insert(
      'user_progress',
      {
        'user_id': 0, // Local user
        'current_page': progress.currentPageIndex,
        'revelation_level': progress.revelationLevel.index + 1,
        'characters_discovered': json.encode(progress.discoveredCharacters),
        'bookmarks': json.encode(progress.bookmarks.map((b) => b.toJson()).toList()),
        'reading_time': progress.totalReadingTime.inMilliseconds,
        'last_updated': DateTime.now().millisecondsSinceEpoch,
        'is_synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  // Get cached user progress
  Future<UserProgress?> getCachedUserProgress() async {
    await initialize();
    final db = _database!;
    
    final results = await db.query(
      'user_progress',
      where: 'user_id = ?',
      whereArgs: [0],
      orderBy: 'last_updated DESC',
      limit: 1,
    );
    
    if (results.isEmpty) return null;
    
    final row = results.first;
    final charactersDiscovered = (json.decode(row['characters_discovered'] as String? ?? '[]') as List)
        .cast<String>();
    final bookmarksJson = json.decode(row['bookmarks'] as String? ?? '[]') as List;
    final bookmarks = bookmarksJson.map((b) => Bookmark.fromJson(b)).toList();
    
    return UserProgress(
      currentPageIndex: row['current_page'] as int,
      revelationLevel: RevealLevel.values[(row['revelation_level'] as int) - 1],
      discoveredCharacters: charactersDiscovered,
      bookmarks: bookmarks,
      totalReadingTime: Duration(milliseconds: row['reading_time'] as int),
    );
  }
  
  // Save annotation offline
  Future<void> saveAnnotationOffline(EnhancedAnnotation annotation, int pageIndex) async {
    await initialize();
    final db = _database!;
    
    await db.insert(
      'annotations',
      {
        'server_id': null,
        'page_index': pageIndex,
        'content_type': annotation.type.toString(),
        'content': annotation.content,
        'selected_text': annotation.selectedText,
        'position': json.encode(annotation.position),
        'styling': json.encode(annotation.styling),
        'character_initials': annotation.characterInitials,
        'annotation_type': annotation.isFixed ? 'fixed' : 'draggable',
        'revelation_level': annotation.minRevelationLevel,
        'is_public': annotation.isCollaborative ? 1 : 0,
        'is_collaborative': annotation.isCollaborative ? 1 : 0,
        'user_id': 0, // Local user
        'metadata': json.encode(annotation.metadata),
        'created_at': annotation.timestamp.millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'is_synced': 0, // Not synced to server
      },
    );
  }
  
  // Get unsynced annotations
  Future<List<Map<String, dynamic>>> getUnsyncedAnnotations() async {
    await initialize();
    final db = _database!;
    
    return await db.query(
      'annotations',
      where: 'is_synced = ? AND server_id IS NULL',
      whereArgs: [0],
    );
  }
  
  // Mark annotation as synced
  Future<void> markAnnotationSynced(int localId, int serverId) async {
    await initialize();
    final db = _database!;
    
    await db.update(
      'annotations',
      {
        'server_id': serverId,
        'is_synced': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
  }
  
  // Track reading session
  Future<void> startReadingSession(String sessionId) async {
    await initialize();
    final db = _database!;
    
    await db.insert(
      'reading_sessions',
      {
        'session_id': sessionId,
        'start_time': DateTime.now().millisecondsSinceEpoch,
        'pages_viewed': json.encode([]),
        'annotations_created': 0,
        'total_time': 0,
        'is_synced': 0,
      },
    );
  }
  
  // End reading session
  Future<void> endReadingSession(String sessionId, List<int> pagesViewed, int annotationsCreated) async {
    await initialize();
    final db = _database!;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Get session start time
    final sessions = await db.query(
      'reading_sessions',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    
    if (sessions.isNotEmpty) {
      final startTime = sessions.first['start_time'] as int;
      final totalTime = now - startTime;
      
      await db.update(
        'reading_sessions',
        {
          'end_time': now,
          'pages_viewed': json.encode(pagesViewed),
          'annotations_created': annotationsCreated,
          'total_time': totalTime,
        },
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
    }
  }
  
  // Cache asset file
  Future<String?> cacheAsset(String assetKey, String assetType, List<int> data) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final assetsDir = Directory('${directory.path}/cached_assets');
      
      if (!await assetsDir.exists()) {
        await assetsDir.create(recursive: true);
      }
      
      final fileName = assetKey.replaceAll(RegExp(r'[^\w\.]'), '_');
      final file = File('${assetsDir.path}/$fileName');
      
      await file.writeAsBytes(data);
      
      // Store in database
      await initialize();
      final db = _database!;
      
      await db.insert(
        'cached_assets',
        {
          'asset_type': assetType,
          'asset_key': assetKey,
          'file_path': file.path,
          'size': data.length,
          'last_accessed': DateTime.now().millisecondsSinceEpoch,
          'expires_at': DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      return file.path;
    } catch (e) {
      debugPrint('Failed to cache asset $assetKey: $e');
      return null;
    }
  }
  
  // Get cached asset
  Future<File?> getCachedAsset(String assetKey) async {
    await initialize();
    final db = _database!;
    
    final results = await db.query(
      'cached_assets',
      where: 'asset_key = ? AND expires_at > ?',
      whereArgs: [assetKey, DateTime.now().millisecondsSinceEpoch],
      limit: 1,
    );
    
    if (results.isEmpty) return null;
    
    final filePath = results.first['file_path'] as String;
    final file = File(filePath);
    
    if (await file.exists()) {
      // Update last accessed
      await db.update(
        'cached_assets',
        {'last_accessed': DateTime.now().millisecondsSinceEpoch},
        where: 'asset_key = ?',
        whereArgs: [assetKey],
      );
      
      return file;
    }
    
    return null;
  }
  
  // Clean up expired assets
  Future<void> cleanupExpiredAssets() async {
    await initialize();
    final db = _database!;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Get expired assets
    final expiredAssets = await db.query(
      'cached_assets',
      where: 'expires_at < ?',
      whereArgs: [now],
    );
    
    // Delete files
    for (final asset in expiredAssets) {
      final filePath = asset['file_path'] as String;
      final file = File(filePath);
      
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (e) {
          debugPrint('Failed to delete expired asset file: $filePath');
        }
      }
    }
    
    // Remove from database
    await db.delete(
      'cached_assets',
      where: 'expires_at < ?',
      whereArgs: [now],
    );
    
    debugPrint('Cleaned up ${expiredAssets.length} expired assets');
  }
  
  // Get database size
  Future<int> getDatabaseSize() async {
    await initialize();
    
    try {
      final dbPath = await getDatabasesPath();
      final fullPath = path.join(dbPath, _dbName);
      final file = File(fullPath);
      
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      debugPrint('Failed to get database size: $e');
    }
    
    return 0;
  }
  
  // Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    await initialize();
    final db = _database!;
    
    final contentCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM content'),
    ) ?? 0;
    
    final annotationCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM annotations'),
    ) ?? 0;
    
    final assetCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM cached_assets'),
    ) ?? 0;
    
    final totalAssetSize = Sqflite.firstIntValue(
      await db.rawQuery('SELECT SUM(size) FROM cached_assets'),
    ) ?? 0;
    
    final databaseSize = await getDatabaseSize();
    
    return {
      'content_pages': contentCount,
      'annotations': annotationCount,
      'cached_assets': assetCount,
      'total_asset_size': totalAssetSize,
      'database_size': databaseSize,
      'last_cleanup': await _getLastCleanupTime(),
    };
  }
  
  Future<DateTime?> _getLastCleanupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('last_cache_cleanup');
    
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    
    return null;
  }
  
  // Clear all cached data
  Future<void> clearCache() async {
    await initialize();
    final db = _database!;
    
    // Clear database tables
    await db.delete('content');
    await db.delete('annotations');
    await db.delete('user_progress');
    await db.delete('reading_sessions');
    await db.delete('cached_assets');
    
    // Delete asset files
    try {
      final directory = await getApplicationDocumentsDirectory();
      final assetsDir = Directory('${directory.path}/cached_assets');
      
      if (await assetsDir.exists()) {
        await assetsDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Failed to delete asset files: $e');
    }
    
    // Update last cleanup time
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_cache_cleanup', DateTime.now().millisecondsSinceEpoch);
    
    debugPrint('Cache cleared successfully');
  }
  
  // Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}