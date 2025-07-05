import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/enhanced_document_models.dart';
import '../providers/enhanced_revelation_provider.dart';
import '../services/advanced_search_service.dart';
import '../widgets/navigation/advanced_search_widget.dart';
import '../widgets/navigation/table_of_contents_widget.dart';
import '../widgets/analytics/reading_analytics_widget.dart';

class AdvancedNavigationScreen extends StatefulWidget {
  final Function(int pageNumber)? onPageSelected;
  final int? currentPage;

  const AdvancedNavigationScreen({
    super.key,
    this.onPageSelected,
    this.currentPage,
  });

  @override
  State<AdvancedNavigationScreen> createState() => _AdvancedNavigationScreenState();
}

class _AdvancedNavigationScreenState extends State<AdvancedNavigationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final AdvancedSearchService _searchService = AdvancedSearchService();
  
  int _currentTabIndex = 0;
  bool _isLoading = true;
  
  final List<NavigationTab> _tabs = [
    NavigationTab(
      title: 'Search',
      icon: Icons.search,
      activeIcon: Icons.search,
      color: Colors.blue,
    ),
    NavigationTab(
      title: 'Contents',
      icon: Icons.list_alt,
      activeIcon: Icons.list_alt,
      color: Colors.green,
    ),
    NavigationTab(
      title: 'Analytics',
      icon: Icons.analytics,
      activeIcon: Icons.analytics,
      color: Colors.purple,
    ),
    NavigationTab(
      title: 'Bookmarks',
      icon: Icons.bookmark_border,
      activeIcon: Icons.bookmark,
      color: Colors.amber,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _initializeNavigation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _initializeNavigation() async {
    try {
      await _searchService.initialize();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing navigation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedRevelationProvider>(
      builder: (context, provider, child) {
        if (_isLoading) {
          return _buildLoadingScreen();
        }
        
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: _buildAdvancedAppBar(provider),
          body: Column(
            children: [
              // Navigation stats bar
              _buildNavigationStatsBar(provider),
              
              // Tab content
              Expanded(child: _buildTabContent(provider)),
            ],
          ),
          bottomNavigationBar: _buildBottomTabBar(),
        );
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Initializing Navigation...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Loading search index and analytics',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAdvancedAppBar(EnhancedRevelationProvider provider) {
    final currentTab = _tabs[_currentTabIndex];
    
    return AppBar(
      backgroundColor: currentTab.color,
      elevation: 0,
      title: Row(
        children: [
          Icon(currentTab.activeIcon, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          Text(
            'Advanced ${currentTab.title}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        // Quick navigation to current page
        if (widget.currentPage != null)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Page ${widget.currentPage}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        
        // Settings menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.file_download),
                title: Text('Export Data'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'help',
              child: ListTile(
                leading: Icon(Icons.help),
                title: Text('Help'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationStatsBar(EnhancedRevelationProvider provider) {
    final readingProgress = _searchService.getReadingProgress();
    final totalBookmarks = _searchService.getBookmarks().length;
    final discoveredCharacters = provider.getDiscoveredCharacters().length;
    final currentLevel = provider.currentRevelationLevel;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // Reading progress
          Expanded(
            child: _buildStatItem(
              Icons.trending_up,
              'Progress',
              '${(readingProgress * 100).toInt()}%',
              Colors.blue,
            ),
          ),
          
          Container(width: 1, height: 30, color: Colors.grey[300]),
          
          // Bookmarks
          Expanded(
            child: _buildStatItem(
              Icons.bookmark,
              'Bookmarks',
              totalBookmarks.toString(),
              Colors.amber,
            ),
          ),
          
          Container(width: 1, height: 30, color: Colors.grey[300]),
          
          // Characters
          Expanded(
            child: _buildStatItem(
              Icons.people,
              'Characters',
              '$discoveredCharacters/6',
              Colors.green,
            ),
          ),
          
          Container(width: 1, height: 30, color: Colors.grey[300]),
          
          // Revelation level
          Expanded(
            child: _buildStatItem(
              Icons.visibility,
              'Level',
              _getRevelationLevelShort(currentLevel),
              _getRevelationLevelColor(currentLevel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(EnhancedRevelationProvider provider) {
    return TabBarView(
      controller: _tabController,
      children: [
        // Search tab
        AdvancedSearchWidget(
          onPageSelected: widget.onPageSelected,
          onAnnotationSelected: (annotation) {
            widget.onPageSelected?.call(annotation.pageNumber);
          },
          onCharacterSelected: (character) {
            // Navigate to character screen or show character details
            _showCharacterDetails(character);
          },
        ),
        
        // Table of Contents tab
        TableOfContentsWidget(
          onPageSelected: widget.onPageSelected,
          currentPage: widget.currentPage,
        ),
        
        // Analytics tab
        const ReadingAnalyticsWidget(),
        
        // Bookmarks tab
        _buildBookmarksTab(provider),
      ],
    );
  }

  Widget _buildBookmarksTab(EnhancedRevelationProvider provider) {
    final bookmarks = _searchService.getBookmarks();
    
    if (bookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Bookmarks Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bookmark pages as you read to find them quickly later.',
              style: TextStyle(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Switch to contents tab
                _tabController.animateTo(1);
              },
              icon: const Icon(Icons.list_alt),
              label: const Text('Browse Contents'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = bookmarks[index];
        return _buildBookmarkCard(bookmark, provider);
      },
    );
  }

  Widget _buildBookmarkCard(PageBookmark bookmark, EnhancedRevelationProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.amber,
          child: Text(
            bookmark.pageNumber.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          bookmark.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Page ${bookmark.pageNumber}'),
            if (bookmark.note.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                bookmark.note,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Added ${_formatDate(bookmark.createdAt)}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleBookmarkAction(action, bookmark),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit Note'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('Share'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () {
          widget.onPageSelected?.call(bookmark.pageNumber);
          HapticFeedback.lightImpact();
        },
      ),
    );
  }

  Widget _buildBottomTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        tabs: _tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = index == _currentTabIndex;
          
          return Tab(
            icon: Icon(
              isSelected ? tab.activeIcon : tab.icon,
              color: isSelected ? tab.color : Colors.grey[400],
            ),
            text: tab.title,
          );
        }).toList(),
        labelColor: _tabs[_currentTabIndex].color,
        unselectedLabelColor: Colors.grey[400],
        indicator: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: _tabs[_currentTabIndex].color,
              width: 3,
            ),
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
      ),
    );
  }

  String _getRevelationLevelShort(RevealLevel level) {
    switch (level) {
      case RevealLevel.academic:
        return 'L1';
      case RevealLevel.personalNotes:
        return 'L2';
      case RevealLevel.suspiciousActivity:
        return 'L3';
      case RevealLevel.supernaturalEvents:
        return 'L4';
      case RevealLevel.completeTruth:
        return 'L5';
    }
  }

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

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _showExportDialog();
        break;
      case 'settings':
        _showSettingsDialog();
        break;
      case 'help':
        _showHelpDialog();
        break;
    }
  }

  void _handleBookmarkAction(String action, PageBookmark bookmark) {
    switch (action) {
      case 'edit':
        _editBookmarkNote(bookmark);
        break;
      case 'share':
        _shareBookmark(bookmark);
        break;
      case 'delete':
        _deleteBookmark(bookmark);
        break;
    }
  }

  void _showCharacterDetails(Character character) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Character details
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Character header
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
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      character.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (character.isMissing)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'MISSING PERSON',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Description
                          Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            character.description,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          
                          if (character.lastSeen != null) ...[
                            const SizedBox(height: 24),
                            Text(
                              'Last Seen',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              character.lastSeen!,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Export Navigation Data'),
          content: const Text(
            'Export your bookmarks, reading progress, and analytics data.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Implement export functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Export functionality coming soon'),
                  ),
                );
              },
              child: const Text('Export'),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Navigation Settings'),
          content: const Text(
            'Configure search preferences, bookmark options, and analytics tracking.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Navigation Help'),
          content: const SingleChildScrollView(
            child: Text(
              'Advanced Navigation Features:\n\n'
              '• Search: Find content across all 247 pages\n'
              '• Contents: Navigate by sections and chapters\n'
              '• Analytics: Track your reading progress\n'
              '• Bookmarks: Save important pages\n\n'
              'Use filters and advanced options to refine your search and discovery experience.',
              style: TextStyle(height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  void _editBookmarkNote(PageBookmark bookmark) {
    final noteController = TextEditingController(text: bookmark.note);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Bookmark Note'),
          content: TextField(
            controller: noteController,
            decoration: const InputDecoration(
              labelText: 'Note',
              hintText: 'Add your thoughts about this page...',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Update bookmark note
                final updatedBookmark = PageBookmark(
                  pageNumber: bookmark.pageNumber,
                  title: bookmark.title,
                  note: noteController.text,
                  createdAt: bookmark.createdAt,
                  thumbnailPath: bookmark.thumbnailPath,
                );
                
                _searchService.addBookmark(updatedBookmark);
                Navigator.pop(context);
                setState(() {}); // Refresh bookmarks
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bookmark note updated')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _shareBookmark(PageBookmark bookmark) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing: Page ${bookmark.pageNumber} - ${bookmark.title}'),
      ),
    );
  }

  void _deleteBookmark(PageBookmark bookmark) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Bookmark'),
          content: Text('Remove bookmark for page ${bookmark.pageNumber}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _searchService.removeBookmark(bookmark.pageNumber);
                Navigator.pop(context);
                setState(() {}); // Refresh bookmarks
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bookmark deleted')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

// Data model for navigation tabs
class NavigationTab {
  final String title;
  final IconData icon;
  final IconData activeIcon;
  final Color color;

  NavigationTab({
    required this.title,
    required this.icon,
    required this.activeIcon,
    required this.color,
  });
}