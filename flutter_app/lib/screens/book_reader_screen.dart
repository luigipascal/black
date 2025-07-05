import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/document_models.dart';
import '../providers/document_state.dart';
import '../providers/access_provider.dart';
import '../services/content_loader.dart';
import '../widgets/document_page_widget.dart';
import '../constants/app_theme.dart';

class BookReaderScreen extends StatefulWidget {
  const BookReaderScreen({super.key});

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  BookData? _bookData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContent();
    _loadSavedState();
  }

  Future<void> _loadContent() async {
    try {
      await ContentLoader.preloadEssentialData();
      final bookData = await ContentLoader.loadBookData();
      
      setState(() {
        _bookData = bookData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSavedState() async {
    await context.read<DocumentState>().loadFromStorage();
    await context.read<AccessProvider>().loadFromStorage();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_error != null) {
      return _buildErrorScreen();
    }

    if (_bookData == null) {
      return _buildErrorScreen(message: 'No book data loaded');
    }

    return Scaffold(
      backgroundColor: AppTheme.bookCover,
      body: SafeArea(
        child: Column(
          children: [
            // App bar with controls
            _buildAppBar(),
            
            // Main content area
            Expanded(
              child: Consumer<DocumentState>(
                builder: (context, documentState, child) {
                  return _buildBookContent(documentState);
                },
              ),
            ),
            
            // Navigation controls
            _buildNavigationControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppTheme.bookCover,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.amber),
            ),
            SizedBox(height: 16),
            Text(
              'Loading classified documents...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen({String? message}) {
    return Scaffold(
      backgroundColor: AppTheme.bookCover,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              message ?? _error ?? 'An error occurred',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadContent();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.bookSpine,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Blackthorn Manor Archive',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Spacer(),
          _buildReadingModeToggle(),
          const SizedBox(width: 16),
          _buildMenuButton(),
        ],
      ),
    );
  }

  Widget _buildReadingModeToggle() {
    return Consumer<DocumentState>(
      builder: (context, documentState, child) {
        return IconButton(
          icon: Icon(
            documentState.readingMode == ReadingMode.singlePage
                ? Icons.menu_book
                : Icons.description,
            color: Colors.white,
          ),
          onPressed: () {
            documentState.toggleReadingMode();
          },
          tooltip: documentState.readingMode == ReadingMode.singlePage
              ? 'Switch to Book View'
              : 'Switch to Single Page',
        );
      },
    );
  }

  Widget _buildMenuButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (value) {
        switch (value) {
          case 'characters':
            _showCharactersList();
            break;
          case 'reset':
            _showResetDialog();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'characters',
          child: Row(
            children: [
              Icon(Icons.people),
              SizedBox(width: 8),
              Text('Character Guide'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'reset',
          child: Row(
            children: [
              Icon(Icons.refresh),
              SizedBox(width: 8),
              Text('Reset Progress'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookContent(DocumentState documentState) {
    final pages = ContentLoader.getPagesForMode(
      documentState.readingMode,
      documentState.currentPage,
    );

    if (pages.isEmpty) {
      return const Center(
        child: Text(
          'No pages available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    switch (documentState.readingMode) {
      case ReadingMode.singlePage:
        return _buildSinglePageView(pages.first);
      case ReadingMode.bookSpread:
        return _buildBookSpreadView(pages);
    }
  }

  Widget _buildSinglePageView(DocumentPage page) {
    return Center(
      child: InteractiveDocumentPage(
        page: page,
        readingMode: ReadingMode.singlePage,
      ),
    );
  }

  Widget _buildBookSpreadView(List<DocumentPage> pages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Left page
        if (pages.length > 1)
          Flexible(
            child: InteractiveDocumentPage(
              page: pages[0],
              readingMode: ReadingMode.bookSpread,
              isLeftPage: true,
            ),
          ),
        
        // Spine
        Container(
          width: PageDimensions.spineWidth,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black26, Colors.transparent, Colors.black26],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        
        // Right page
        Flexible(
          child: InteractiveDocumentPage(
            page: pages.last,
            readingMode: ReadingMode.bookSpread,
            isLeftPage: false,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationControls() {
    return Consumer<DocumentState>(
      builder: (context, documentState, child) {
        final totalPages = ContentLoader.getTotalPages();
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppTheme.bookSpine,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Previous page
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: documentState.currentPage > 0
                    ? () => documentState.previousPage()
                    : null,
              ),
              
              // Page indicator
              Expanded(
                child: Center(
                  child: Text(
                    'Page ${documentState.currentPage + 1} of $totalPages',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              
              // Next page
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: documentState.currentPage < totalPages - 1
                    ? () => documentState.nextPage()
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCharactersList() {
    showDialog(
      context: context,
      builder: (context) => const CharactersListDialog(),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Progress'),
        content: const Text(
          'This will reset all annotation positions and unlocked content. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<DocumentState>().resetAll();
              context.read<AccessProvider>().resetAccess();
              Navigator.of(context).pop();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class CharactersListDialog extends StatelessWidget {
  const CharactersListDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final characterCodes = ContentLoader.getCharacterCodes();
    
    return AlertDialog(
      title: const Text('Character Guide'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: characterCodes.length,
          itemBuilder: (context, index) {
            final characterCode = characterCodes[index];
            final character = ContentLoader.getCharacter(characterCode);
            
            if (character == null) return const SizedBox.shrink();
            
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _getCharacterColor(characterCode),
                child: Text(
                  characterCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              title: Text(character.name),
              subtitle: Text(character.years),
              trailing: Text(
                character.role,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              onTap: () {
                // Could show detailed character info here
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Color _getCharacterColor(String characterCode) {
    switch (characterCode) {
      case 'MB':
        return AppTheme.marginaliaBlue;
      case 'JR':
        return AppTheme.marginaliaBlack;
      case 'EW':
        return AppTheme.marginaliaRed;
      case 'SW':
        return Colors.brown;
      case 'Detective Sharma':
        return Colors.green;
      case 'Dr. Chambers':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}