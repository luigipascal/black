import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../providers/enhanced_revelation_provider.dart';
import '../models/enhanced_document_models.dart';
import '../services/reading_experience_service.dart';
import '../widgets/reading_experience/adaptive_typography_widget.dart';
import '../widgets/reading_experience/reading_mode_preferences_widget.dart';
import '../widgets/reading_experience/reading_goals_achievements_widget.dart';
import '../widgets/reading_experience/reading_analytics_widget.dart';
import '../widgets/navigation/advanced_search_widget.dart';
import '../widgets/navigation/table_of_contents_widget.dart';
import '../widgets/enhanced_document_page_widget.dart';

class EnhancedReadingExperienceScreen extends StatefulWidget {
  const EnhancedReadingExperienceScreen({super.key});

  @override
  State<EnhancedReadingExperienceScreen> createState() => _EnhancedReadingExperienceScreenState();
}

class _EnhancedReadingExperienceScreenState extends State<EnhancedReadingExperienceScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final ReadingExperienceService _readingService = ReadingExperienceService();
  final PageController _pageController = PageController();
  
  int _currentPageIndex = 0;
  DateTime _sessionStartTime = DateTime.now();
  List<EnhancedAnnotation> _viewedAnnotations = [];
  bool _isFullscreen = false;
  bool _showControls = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _fadeController.forward();
    _startReadingSession();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _pageController.dispose();
    _endReadingSession();
    super.dispose();
  }
  
  void _startReadingSession() {
    _sessionStartTime = DateTime.now();
    _readingService.startReadingSession();
  }
  
  void _endReadingSession() {
    final sessionDuration = DateTime.now().difference(_sessionStartTime);
    _readingService.endReadingSession(_currentPageIndex, sessionDuration);
  }
  
  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      _showControls = !_isFullscreen;
    });
    
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }
  
  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }
  
  void _onPageChanged(int pageIndex) {
    setState(() {
      _currentPageIndex = pageIndex;
    });
    
    HapticFeedback.lightImpact();
    _readingService.trackPageView(pageIndex);
  }
  
  void _onAnnotationViewed(EnhancedAnnotation annotation) {
    if (!_viewedAnnotations.contains(annotation)) {
      setState(() {
        _viewedAnnotations.add(annotation);
      });
    }
  }
  
  void _jumpToPage(int pageIndex) {
    _pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedRevelationProvider>(
      builder: (context, provider, child) {
        final pages = provider.pages;
        final currentPage = pages.isNotEmpty ? pages[_currentPageIndex] : null;
        
        return Scaffold(
          body: _isFullscreen
              ? _buildFullscreenReader(provider, pages)
              : _buildTabbedInterface(provider, pages, currentPage),
          floatingActionButton: _buildFloatingActionButton(),
          floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
        );
      },
    );
  }
  
  Widget _buildFullscreenReader(EnhancedRevelationProvider provider, List<EnhancedDocumentPage> pages) {
    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        children: [
          // Full-screen page reader
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: pages.length,
            itemBuilder: (context, index) {
              return AdaptiveTypographyWidget(
                page: pages[index],
                pageIndex: index,
                totalPages: pages.length,
                onAnnotationViewed: _onAnnotationViewed,
                isFullscreen: true,
              );
            },
          ),
          
          // Overlay controls
          if (_showControls)
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: _buildOverlayControls(provider, pages),
            ),
        ],
      ),
    );
  }
  
  Widget _buildTabbedInterface(EnhancedRevelationProvider provider, List<EnhancedDocumentPage> pages, EnhancedDocumentPage? currentPage) {
    return Column(
      children: [
        // App bar with reading progress
        _buildAppBar(provider, pages),
        
        // Tab bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Reader', icon: Icon(Icons.book, size: 18)),
              Tab(text: 'Analytics', icon: Icon(Icons.analytics, size: 18)),
              Tab(text: 'Settings', icon: Icon(Icons.settings, size: 18)),
              Tab(text: 'Search', icon: Icon(Icons.search, size: 18)),
              Tab(text: 'Contents', icon: Icon(Icons.list, size: 18)),
            ],
          ),
        ),
        
        // Tab content
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReaderTab(provider, pages),
                _buildAnalyticsTab(provider, pages),
                _buildSettingsTab(provider),
                _buildSearchTab(provider, pages),
                _buildContentsTab(provider, pages),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildAppBar(EnhancedRevelationProvider provider, List<EnhancedDocumentPage> pages) {
    final progress = pages.isNotEmpty ? (_currentPageIndex + 1) / pages.length : 0.0;
    
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.white,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // Title and controls
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Expanded(
                child: Text(
                  'Enhanced Reading Experience',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(_isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
                onPressed: _toggleFullscreen,
              ),
            ],
          ),
          
          // Progress bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Page ${_currentPageIndex + 1} of ${pages.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.lerp(Colors.blue, Colors.purple, progress) ?? Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReaderTab(EnhancedRevelationProvider provider, List<EnhancedDocumentPage> pages) {
    return Stack(
      children: [
        // Page reader
        PageView.builder(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          itemCount: pages.length,
          itemBuilder: (context, index) {
            return AdaptiveTypographyWidget(
              page: pages[index],
              pageIndex: index,
              totalPages: pages.length,
              onAnnotationViewed: _onAnnotationViewed,
              isFullscreen: false,
            );
          },
        ),
        
        // Navigation controls
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: _buildNavigationControls(pages),
        ),
      ],
    );
  }
  
  Widget _buildAnalyticsTab(EnhancedRevelationProvider provider, List<EnhancedDocumentPage> pages) {
    final sessionDuration = DateTime.now().difference(_sessionStartTime);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Session overview
          _buildSessionOverview(sessionDuration),
          
          const SizedBox(height: 20),
          
          // Reading analytics
          ReadingAnalyticsWidget(
            currentPageIndex: _currentPageIndex,
            totalPages: pages.length,
            sessionDuration: sessionDuration,
            viewedAnnotations: _viewedAnnotations,
          ),
          
          const SizedBox(height: 20),
          
          // Goals and achievements
          ReadingGoalsAchievementsWidget(
            currentPageIndex: _currentPageIndex,
            totalPages: pages.length,
            sessionDuration: sessionDuration,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSettingsTab(EnhancedRevelationProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Reading mode preferences
          ReadingModePreferencesWidget(
            onModeChanged: (mode) {
              // Handle reading mode change
              HapticFeedback.lightImpact();
            },
          ),
          
          const SizedBox(height: 20),
          
          // Typography settings
          _buildTypographySettings(),
          
          const SizedBox(height: 20),
          
          // Accessibility settings
          _buildAccessibilitySettings(),
          
          const SizedBox(height: 20),
          
          // Data management
          _buildDataManagement(),
        ],
      ),
    );
  }
  
  Widget _buildSearchTab(EnhancedRevelationProvider provider, List<EnhancedDocumentPage> pages) {
    return AdvancedSearchWidget(
      pages: pages,
      onPageSelected: _jumpToPage,
      onAnnotationSelected: (annotation) {
        // Jump to page with annotation
        final pageIndex = pages.indexWhere((page) => 
          page.annotations.contains(annotation));
        if (pageIndex != -1) {
          _jumpToPage(pageIndex);
          _tabController.animateTo(0); // Switch to reader tab
        }
      },
    );
  }
  
  Widget _buildContentsTab(EnhancedRevelationProvider provider, List<EnhancedDocumentPage> pages) {
    return TableOfContentsWidget(
      pages: pages,
      currentPageIndex: _currentPageIndex,
      onPageSelected: _jumpToPage,
      onSectionSelected: (sectionIndex) {
        _jumpToPage(sectionIndex);
        _tabController.animateTo(0); // Switch to reader tab
      },
    );
  }
  
  Widget _buildOverlayControls(EnhancedRevelationProvider provider, List<EnhancedDocumentPage> pages) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _toggleFullscreen,
            ),
            Text(
              'Page ${_currentPageIndex + 1} of ${pages.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {
                // Show fullscreen menu
                _showFullscreenMenu(provider, pages);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNavigationControls(List<EnhancedDocumentPage> pages) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_left),
            onPressed: _currentPageIndex > 0
                ? () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  )
                : null,
          ),
          Expanded(
            child: Slider(
              value: _currentPageIndex.toDouble(),
              min: 0,
              max: (pages.length - 1).toDouble(),
              divisions: pages.length - 1,
              onChanged: (value) {
                _jumpToPage(value.toInt());
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_right),
            onPressed: _currentPageIndex < pages.length - 1
                ? () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  )
                : null,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSessionOverview(Duration sessionDuration) {
    final readingSpeed = _currentPageIndex > 0 
        ? (_currentPageIndex / sessionDuration.inMinutes) * 60 
        : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.purple.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Session',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSessionStat(
                'Duration',
                '${sessionDuration.inMinutes}m ${sessionDuration.inSeconds % 60}s',
                Icons.timer,
                Colors.blue,
              ),
              _buildSessionStat(
                'Pages',
                '${_currentPageIndex + 1}',
                Icons.book,
                Colors.green,
              ),
              _buildSessionStat(
                'Speed',
                '${readingSpeed.toStringAsFixed(1)} p/h',
                Icons.speed,
                Colors.orange,
              ),
              _buildSessionStat(
                'Annotations',
                '${_viewedAnnotations.length}',
                Icons.note,
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSessionStat(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
  
  Widget _buildTypographySettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Typography Settings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Font Size'),
            subtitle: const Text('Adjust reading font size'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Show font size slider
            },
          ),
          ListTile(
            leading: const Icon(Icons.format_line_spacing),
            title: const Text('Line Spacing'),
            subtitle: const Text('Adjust line height'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Show line spacing options
            },
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Color Theme'),
            subtitle: const Text('Light, dark, or sepia'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Show theme selector
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildAccessibilitySettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Accessibility',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: const Text('Haptic Feedback'),
            subtitle: const Text('Vibrate on interactions'),
            value: true,
            onChanged: (value) {
              // Toggle haptic feedback
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.accessibility),
            title: const Text('High Contrast'),
            subtitle: const Text('Improve text readability'),
            value: false,
            onChanged: (value) {
              // Toggle high contrast mode
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.zoom_in),
            title: const Text('Magnification'),
            subtitle: const Text('Enable pinch to zoom'),
            value: true,
            onChanged: (value) {
              // Toggle magnification
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildDataManagement() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Management',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.cloud_download),
            title: const Text('Export Progress'),
            subtitle: const Text('Save reading data'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Export reading progress
            },
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup Settings'),
            subtitle: const Text('Save preferences'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Backup settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Clear Data'),
            subtitle: const Text('Reset all progress'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Show clear data confirmation
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      mini: true,
      backgroundColor: Colors.blue,
      onPressed: () {
        // Show quick actions menu
        _showQuickActionsMenu();
      },
      child: const Icon(Icons.menu, color: Colors.white),
    );
  }
  
  void _showFullscreenMenu(EnhancedRevelationProvider provider, List<EnhancedDocumentPage> pages) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reading Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search'),
              onTap: () {
                Navigator.pop(context);
                // Show search overlay
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('Bookmark'),
              onTap: () {
                Navigator.pop(context);
                // Add bookmark
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                // Share current page
              },
            ),
          ],
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
  
  void _showQuickActionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bookmark_add),
              title: const Text('Add Bookmark'),
              onTap: () {
                Navigator.pop(context);
                // Add bookmark functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_add),
              title: const Text('Add Note'),
              onTap: () {
                Navigator.pop(context);
                // Add note functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Page'),
              onTap: () {
                Navigator.pop(context);
                // Share functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(2); // Switch to settings tab
              },
            ),
          ],
        ),
      ),
    );
  }
}