import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/enhanced_document_models.dart';
import '../../providers/enhanced_revelation_provider.dart';
import '../../services/advanced_search_service.dart';

class TableOfContentsWidget extends StatefulWidget {
  final Function(int pageNumber)? onPageSelected;
  final int? currentPage;

  const TableOfContentsWidget({
    super.key,
    this.onPageSelected,
    this.currentPage,
  });

  @override
  State<TableOfContentsWidget> createState() => _TableOfContentsWidgetState();
}

class _TableOfContentsWidgetState extends State<TableOfContentsWidget>
    with TickerProviderStateMixin {
  final AdvancedSearchService _searchService = AdvancedSearchService();
  late AnimationController _sectionController;
  late Animation<double> _sectionAnimation;
  
  int _selectedSection = 0;
  List<BookSection> _sections = [];
  List<PageBookmark> _bookmarks = [];
  bool _showBookmarksOnly = false;
  
  final List<String> _sectionNames = [
    'Front Matter',
    'Main Content',
    'Appendices',
  ];

  @override
  void initState() {
    super.initState();
    
    _sectionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _sectionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sectionController,
      curve: Curves.easeInOut,
    ));
    
    _initializeContents();
    _loadBookmarks();
    _sectionController.forward();
  }

  @override
  void dispose() {
    _sectionController.dispose();
    super.dispose();
  }

  void _initializeContents() {
    _sections = [
      // Front Matter (Pages 1-26)
      BookSection(
        title: 'Front Matter',
        startPage: 1,
        endPage: 26,
        icon: Icons.article_outlined,
        color: Colors.blue,
        subsections: [
          BookSubsection(title: 'Title Page', pageNumber: 1),
          BookSubsection(title: 'Disclaimer', pageNumber: 2),
          BookSubsection(title: 'Dedication', pageNumber: 3),
          BookSubsection(title: 'Foreword', pageNumber: 4),
          BookSubsection(title: 'Table of Contents', pageNumber: 8),
          BookSubsection(title: 'Introduction', pageNumber: 12),
        ],
      ),
      
      // Main Content (Pages 27-101)
      BookSection(
        title: 'Main Content',
        startPage: 27,
        endPage: 101,
        icon: Icons.book_outlined,
        color: Colors.green,
        subsections: [
          BookSubsection(title: 'Chapter 1: Historical Overview', pageNumber: 27),
          BookSubsection(title: 'Chapter 2: Architectural Analysis', pageNumber: 35),
          BookSubsection(title: 'Chapter 3: The Blackthorn Family', pageNumber: 43),
          BookSubsection(title: 'Chapter 4: Notable Events', pageNumber: 51),
          BookSubsection(title: 'Chapter 5: Current State', pageNumber: 59),
          BookSubsection(title: 'Chapter 6: Recommendations', pageNumber: 67),
          BookSubsection(title: 'Chapter 7: Mysteries Uncovered', pageNumber: 75),
          BookSubsection(title: 'Chapter 8: The Investigation', pageNumber: 83),
          BookSubsection(title: 'Chapter 9: Supernatural Elements', pageNumber: 91),
          BookSubsection(title: 'Chapter 10: Conclusions', pageNumber: 99),
        ],
      ),
      
      // Appendices (Pages 102-247)
      BookSection(
        title: 'Appendices',
        startPage: 102,
        endPage: 247,
        icon: Icons.folder_outlined,
        color: Colors.orange,
        subsections: [
          BookSubsection(title: 'Appendix A: Floor Plans', pageNumber: 102),
          BookSubsection(title: 'Appendix B: Genealogy', pageNumber: 120),
          BookSubsection(title: 'Appendix C: Timeline', pageNumber: 145),
          BookSubsection(title: 'Appendix D: Correspondence', pageNumber: 165),
          BookSubsection(title: 'Appendix E: Research Notes', pageNumber: 185),
          BookSubsection(title: 'Appendix F: Missing Persons', pageNumber: 205),
          BookSubsection(title: 'Appendix G: Supernatural Evidence', pageNumber: 225),
          BookSubsection(title: 'Bibliography', pageNumber: 240),
          BookSubsection(title: 'Index', pageNumber: 245),
        ],
      ),
    ];
  }

  void _loadBookmarks() {
    _bookmarks = _searchService.getBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedRevelationProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Header
            _buildHeader(),
            
            // Section tabs
            _buildSectionTabs(),
            
            // Content
            Expanded(child: _buildSectionContent(provider)),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(Icons.list_alt, color: Colors.indigo[600], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Table of Contents',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[800],
              ),
            ),
          ),
          
          // Bookmark filter toggle
          IconButton(
            icon: Icon(
              _showBookmarksOnly ? Icons.bookmark : Icons.bookmark_border,
              color: _showBookmarksOnly ? Colors.amber : Colors.indigo[600],
            ),
            onPressed: () {
              setState(() {
                _showBookmarksOnly = !_showBookmarksOnly;
              });
              HapticFeedback.lightImpact();
            },
            tooltip: _showBookmarksOnly ? 'Show all pages' : 'Show bookmarks only',
          ),
          
          // Reading progress
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.indigo[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${(_searchService.getReadingProgress() * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTabs() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _sections.asMap().entries.map((entry) {
          final index = entry.key;
          final section = entry.value;
          final isSelected = index == _selectedSection;
          
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSection = index;
                });
                _sectionController.reset();
                _sectionController.forward();
                HapticFeedback.lightImpact();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? section.color : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? section.color : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      section.icon,
                      color: isSelected ? Colors.white : section.color,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      section.title,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : section.color,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionContent(EnhancedRevelationProvider provider) {
    final section = _sections[_selectedSection];
    
    return AnimatedBuilder(
      animation: _sectionAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (_sectionAnimation.value * 0.2),
          child: Opacity(
            opacity: _sectionAnimation.value,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Section header
                  _buildSectionHeader(section, provider),
                  
                  // Section content
                  Expanded(child: _buildSectionList(section, provider)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BookSection section, EnhancedRevelationProvider provider) {
    final pagesInSection = section.endPage - section.startPage + 1;
    final readPagesInSection = _getReadPagesInSection(section);
    final progress = readPagesInSection / pagesInSection;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: section.color.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(section.icon, color: section.color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  section.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: section.color,
                  ),
                ),
              ),
              Text(
                'Pages ${section.startPage}-${section.endPage}',
                style: TextStyle(
                  fontSize: 12,
                  color: section.color,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Progress bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(section.color),
            minHeight: 4,
          ),
          
          const SizedBox(height: 4),
          
          Text(
            '${(progress * 100).toInt()}% complete ($readPagesInSection/$pagesInSection pages)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionList(BookSection section, EnhancedRevelationProvider provider) {
    List<Widget> items = [];
    
    if (_showBookmarksOnly) {
      // Show only bookmarks in this section
      final sectionBookmarks = _bookmarks.where((bookmark) =>
          bookmark.pageNumber >= section.startPage && 
          bookmark.pageNumber <= section.endPage).toList();
      
      if (sectionBookmarks.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bookmark_border, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'No bookmarks in this section',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      }
      
      items = sectionBookmarks.map((bookmark) =>
          _buildBookmarkItem(bookmark, section, provider)).toList();
    } else {
      // Show subsections
      for (final subsection in section.subsections) {
        items.add(_buildSubsectionItem(subsection, section, provider));
      }
      
      // Add bookmarks for this section
      final sectionBookmarks = _bookmarks.where((bookmark) =>
          bookmark.pageNumber >= section.startPage && 
          bookmark.pageNumber <= section.endPage).toList();
      
      if (sectionBookmarks.isNotEmpty) {
        items.add(_buildBookmarksSeparator());
        items.addAll(sectionBookmarks.map((bookmark) =>
            _buildBookmarkItem(bookmark, section, provider)));
      }
    }
    
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }

  Widget _buildSubsectionItem(BookSubsection subsection, BookSection section, 
                             EnhancedRevelationProvider provider) {
    final isCurrentPage = widget.currentPage == subsection.pageNumber;
    final isRead = _searchService.isPageRead(subsection.pageNumber);
    final isBookmarked = _searchService.isBookmarked(subsection.pageNumber);
    
    return ListTile(
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: isCurrentPage 
            ? section.color
            : (isRead ? section.color.withOpacity(0.3) : Colors.grey[300]),
        child: Text(
          subsection.pageNumber.toString(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isCurrentPage || isRead ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
      title: Text(
        subsection.title,
        style: TextStyle(
          fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
          color: isCurrentPage ? section.color : null,
        ),
      ),
      subtitle: _buildPageSubtitle(subsection.pageNumber, provider),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isBookmarked)
            Icon(Icons.bookmark, color: Colors.amber, size: 16),
          if (isRead)
            Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
      onTap: () {
        widget.onPageSelected?.call(subsection.pageNumber);
        HapticFeedback.lightImpact();
      },
      onLongPress: () {
        _showPageOptions(subsection.pageNumber, subsection.title);
      },
    );
  }

  Widget _buildBookmarkItem(PageBookmark bookmark, BookSection section, 
                           EnhancedRevelationProvider provider) {
    final isCurrentPage = widget.currentPage == bookmark.pageNumber;
    
    return ListTile(
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.amber,
        child: Icon(
          Icons.bookmark,
          color: Colors.white,
          size: 16,
        ),
      ),
      title: Text(
        bookmark.title,
        style: TextStyle(
          fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
          color: isCurrentPage ? section.color : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Page ${bookmark.pageNumber}'),
          if (bookmark.note.isNotEmpty)
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
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        onPressed: () {
          _removeBookmark(bookmark);
        },
      ),
      onTap: () {
        widget.onPageSelected?.call(bookmark.pageNumber);
        HapticFeedback.lightImpact();
      },
    );
  }

  Widget _buildBookmarksSeparator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.amber[50],
      child: Row(
        children: [
          Icon(Icons.bookmark, color: Colors.amber[700], size: 16),
          const SizedBox(width: 8),
          Text(
            'Bookmarks in this section',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.amber[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageSubtitle(int pageNumber, EnhancedRevelationProvider provider) {
    final annotations = provider.getAnnotationsForPage(pageNumber);
    final readTime = _searchService.getPageReadingTimes()[pageNumber];
    
    final parts = <String>[];
    
    if (annotations.isNotEmpty) {
      parts.add('${annotations.length} annotation${annotations.length > 1 ? 's' : ''}');
    }
    
    if (readTime != null) {
      final minutes = readTime.inMinutes;
      parts.add('${minutes}m read');
    }
    
    if (parts.isEmpty) return null;
    
    return Text(
      parts.join(' • '),
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
      ),
    );
  }

  int _getReadPagesInSection(BookSection section) {
    int count = 0;
    for (int page = section.startPage; page <= section.endPage; page++) {
      if (_searchService.isPageRead(page)) {
        count++;
      }
    }
    return count;
  }

  void _showPageOptions(int pageNumber, String title) {
    final isBookmarked = _searchService.isBookmarked(pageNumber);
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Page $pageNumber Options',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              ListTile(
                leading: Icon(
                  isBookmarked ? Icons.bookmark_remove : Icons.bookmark_add,
                ),
                title: Text(
                  isBookmarked ? 'Remove Bookmark' : 'Add Bookmark',
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (isBookmarked) {
                    _removeBookmark(pageNumber);
                  } else {
                    _addBookmark(pageNumber, title);
                  }
                },
              ),
              
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share Page'),
                onTap: () {
                  Navigator.pop(context);
                  _sharePage(pageNumber, title);
                },
              ),
              
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Page Details'),
                onTap: () {
                  Navigator.pop(context);
                  _showPageDetails(pageNumber);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _addBookmark(int pageNumber, String title) {
    final bookmark = PageBookmark(
      pageNumber: pageNumber,
      title: title,
      createdAt: DateTime.now(),
    );
    
    _searchService.addBookmark(bookmark);
    
    setState(() {
      _loadBookmarks();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bookmark added for page $pageNumber'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () => _removeBookmark(pageNumber),
        ),
      ),
    );
  }

  void _removeBookmark(dynamic bookmarkOrPageNumber) {
    final pageNumber = bookmarkOrPageNumber is PageBookmark
        ? bookmarkOrPageNumber.pageNumber
        : bookmarkOrPageNumber as int;
    
    _searchService.removeBookmark(pageNumber);
    
    setState(() {
      _loadBookmarks();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bookmark removed from page $pageNumber'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _sharePage(int pageNumber, String title) {
    // Implementation for sharing page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share functionality for page $pageNumber'),
      ),
    );
  }

  void _showPageDetails(int pageNumber) {
    final isRead = _searchService.isPageRead(pageNumber);
    final readTime = _searchService.getPageReadingTimes()[pageNumber];
    final isBookmarked = _searchService.isBookmarked(pageNumber);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Page $pageNumber Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Status', isRead ? 'Read' : 'Unread'),
              if (readTime != null)
                _buildDetailRow('Reading Time', '${readTime.inMinutes}m ${readTime.inSeconds % 60}s'),
              _buildDetailRow('Bookmarked', isBookmarked ? 'Yes' : 'No'),
            ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}

// Data models for table of contents
class BookSection {
  final String title;
  final int startPage;
  final int endPage;
  final IconData icon;
  final Color color;
  final List<BookSubsection> subsections;

  BookSection({
    required this.title,
    required this.startPage,
    required this.endPage,
    required this.icon,
    required this.color,
    required this.subsections,
  });
}

class BookSubsection {
  final String title;
  final int pageNumber;

  BookSubsection({
    required this.title,
    required this.pageNumber,
  });
}