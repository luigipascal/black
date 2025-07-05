import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../services/advanced_search_service.dart';
import '../../models/enhanced_document_models.dart';
import '../../providers/enhanced_revelation_provider.dart';

class AdvancedSearchWidget extends StatefulWidget {
  final Function(int pageNumber)? onPageSelected;
  final Function(EnhancedAnnotation annotation)? onAnnotationSelected;
  final Function(Character character)? onCharacterSelected;

  const AdvancedSearchWidget({
    super.key,
    this.onPageSelected,
    this.onAnnotationSelected,
    this.onCharacterSelected,
  });

  @override
  State<AdvancedSearchWidget> createState() => _AdvancedSearchWidgetState();
}

class _AdvancedSearchWidgetState extends State<AdvancedSearchWidget>
    with TickerProviderStateMixin {
  final AdvancedSearchService _searchService = AdvancedSearchService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  late AnimationController _resultsController;
  late AnimationController _filtersController;
  late Animation<double> _resultsAnimation;
  late Animation<double> _filtersAnimation;
  
  SearchResults? _currentResults;
  List<String> _suggestions = [];
  bool _isSearching = false;
  bool _showFilters = false;
  bool _showSuggestions = false;
  
  Timer? _debounceTimer;
  Timer? _suggestionTimer;
  
  // Filter options
  bool _includePages = true;
  bool _includeAnnotations = true;
  bool _includeCharacters = true;
  List<String> _selectedCharacters = [];
  RevealLevel? _minRevelationLevel;
  DateTimeRange? _dateRange;
  
  @override
  void initState() {
    super.initState();
    
    _resultsController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _filtersController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _resultsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _resultsController,
      curve: Curves.easeInOut,
    ));
    
    _filtersAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _filtersController,
      curve: Curves.easeInOut,
    ));
    
    _searchController.addListener(_onSearchTextChanged);
    _searchFocusNode.addListener(_onFocusChanged);
    
    _initializeSearchService();
  }

  @override
  void dispose() {
    _resultsController.dispose();
    _filtersController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    _suggestionTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeSearchService() async {
    await _searchService.initialize();
  }

  void _onSearchTextChanged() {
    final query = _searchController.text;
    
    _debounceTimer?.cancel();
    _suggestionTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _currentResults = null;
      });
      _resultsController.reverse();
      return;
    }
    
    // Show suggestions after short delay
    _suggestionTimer = Timer(const Duration(milliseconds: 100), () {
      _loadSuggestions(query);
    });
    
    // Perform search after longer delay
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  void _onFocusChanged() {
    setState(() {
      _showSuggestions = _searchFocusNode.hasFocus && _suggestions.isNotEmpty;
    });
  }

  Future<void> _loadSuggestions(String query) async {
    if (query.length < 2) return;
    
    final suggestions = await _searchService.getSuggestions(query);
    setState(() {
      _suggestions = suggestions;
      _showSuggestions = _searchFocusNode.hasFocus && suggestions.isNotEmpty;
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    
    setState(() {
      _isSearching = true;
      _showSuggestions = false;
    });
    
    final searchQuery = SearchQuery(
      searchText: query,
      includePages: _includePages,
      includeAnnotations: _includeAnnotations,
      includeCharacters: _includeCharacters,
      characters: _selectedCharacters,
      minRevelationLevel: _minRevelationLevel,
      dateRange: _dateRange,
    );
    
    try {
      final results = await _searchService.search(searchQuery);
      
      setState(() {
        _currentResults = results;
        _isSearching = false;
      });
      
      if (results.totalResults > 0) {
        _resultsController.forward();
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search error: $e'),
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
        return Column(
          children: [
            // Search header
            _buildSearchHeader(),
            
            // Search input with suggestions
            _buildSearchInput(),
            
            // Search filters
            if (_showFilters)
              _buildSearchFilters(provider),
            
            // Search results
            if (_currentResults != null)
              Expanded(child: _buildSearchResults()),
          ],
        );
      },
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.blue[600], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Advanced Search',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
          ),
          
          // Filter toggle
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: Colors.blue[600],
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
              
              if (_showFilters) {
                _filtersController.forward();
              } else {
                _filtersController.reverse();
              }
            },
          ),
          
          // Recent searches
          IconButton(
            icon: Icon(Icons.history, color: Colors.blue[600]),
            onPressed: () => _showRecentSearches(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search field
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Search across all 247 pages, annotations, and characters...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchFocusNode.unfocus();
                          },
                        )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
              ),
            ),
            onSubmitted: _performSearch,
          ),
          
          // Suggestions dropdown
          if (_showSuggestions && _suggestions.isNotEmpty)
            _buildSuggestionsDropdown(),
        ],
      ),
    );
  }

  Widget _buildSuggestionsDropdown() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.history, size: 16),
            title: Text(suggestion),
            onTap: () {
              _searchController.text = suggestion;
              _searchController.selection = TextSelection.fromPosition(
                TextPosition(offset: suggestion.length),
              );
              _performSearch(suggestion);
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchFilters(EnhancedRevelationProvider provider) {
    return AnimatedBuilder(
      animation: _filtersAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _filtersAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Content type filters
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Pages'),
                      selected: _includePages,
                      onSelected: (selected) {
                        setState(() {
                          _includePages = selected;
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Annotations'),
                      selected: _includeAnnotations,
                      onSelected: (selected) {
                        setState(() {
                          _includeAnnotations = selected;
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Characters'),
                      selected: _includeCharacters,
                      onSelected: (selected) {
                        setState(() {
                          _includeCharacters = selected;
                        });
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Character filter
                if (provider.characters.isNotEmpty) ...[
                  Text(
                    'Characters',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: provider.characters.values.map((character) {
                      final isSelected = _selectedCharacters.contains(character.name);
                      return FilterChip(
                        label: Text(character.name),
                        selected: isSelected,
                        avatar: CircleAvatar(
                          radius: 8,
                          backgroundColor: character.primaryColor,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCharacters.add(character.name);
                            } else {
                              _selectedCharacters.remove(character.name);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
                
                const SizedBox(height: 12),
                
                // Revelation level filter
                Text(
                  'Minimum Revelation Level',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButton<RevealLevel?>(
                  value: _minRevelationLevel,
                  hint: const Text('Any level'),
                  items: [
                    const DropdownMenuItem<RevealLevel?>(
                      value: null,
                      child: Text('Any level'),
                    ),
                    ...RevealLevel.values.map((level) {
                      return DropdownMenuItem<RevealLevel>(
                        value: level,
                        child: Text(level.toString().split('.').last),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _minRevelationLevel = value;
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return AnimatedBuilder(
      animation: _resultsAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _resultsAnimation.value,
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
                // Results header
                _buildResultsHeader(),
                
                // Results list
                Expanded(child: _buildResultsList()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultsHeader() {
    final results = _currentResults!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(Icons.search_outlined, color: Colors.blue[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${results.totalResults} results found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
          ),
          Text(
            'in ${results.searchDuration.inMilliseconds}ms',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    final results = _currentResults!;
    final allResults = <Widget>[];
    
    // Add page results
    if (results.pageResults.isNotEmpty) {
      allResults.add(_buildResultSection('Pages', results.pageResults.length));
      allResults.addAll(results.pageResults.map(_buildPageResult));
    }
    
    // Add annotation results
    if (results.annotationResults.isNotEmpty) {
      allResults.add(_buildResultSection('Annotations', results.annotationResults.length));
      allResults.addAll(results.annotationResults.map(_buildAnnotationResult));
    }
    
    // Add character results
    if (results.characterResults.isNotEmpty) {
      allResults.add(_buildResultSection('Characters', results.characterResults.length));
      allResults.addAll(results.characterResults.map(_buildCharacterResult));
    }
    
    return ListView.builder(
      itemCount: allResults.length,
      itemBuilder: (context, index) => allResults[index],
    );
  }

  Widget _buildResultSection(String title, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageResult(PageSearchResult result) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue[100],
        child: Text(
          result.page.pageNumber.toString(),
          style: TextStyle(
            color: Colors.blue[800],
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      title: Text(
        'Page ${result.page.pageNumber}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        result.snippet,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '${result.matches.length} matches',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      onTap: () {
        widget.onPageSelected?.call(result.page.pageNumber);
        HapticFeedback.lightImpact();
      },
    );
  }

  Widget _buildAnnotationResult(AnnotationSearchResult result) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.orange[100],
        child: Icon(
          Icons.note,
          color: Colors.orange[800],
          size: 20,
        ),
      ),
      title: Text(
        '${result.annotation.character} - Page ${result.annotation.pageNumber}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        result.snippet,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '${result.matches.length} matches',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      onTap: () {
        widget.onAnnotationSelected?.call(result.annotation);
        HapticFeedback.lightImpact();
      },
    );
  }

  Widget _buildCharacterResult(CharacterSearchResult result) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: result.character.primaryColor,
        child: Text(
          result.character.name.substring(0, 2),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      title: Text(
        result.character.fullName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        result.character.description,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        result.matchedField,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      onTap: () {
        widget.onCharacterSelected?.call(result.character);
        HapticFeedback.lightImpact();
      },
    );
  }

  void _showRecentSearches() {
    final recentSearches = _searchService.getRecentSearches();
    
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
                'Recent Searches',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),
              
              if (recentSearches.isEmpty)
                const Center(
                  child: Text('No recent searches'),
                )
              else
                ...recentSearches.map((search) {
                  return ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(search),
                    onTap: () {
                      Navigator.pop(context);
                      _searchController.text = search;
                      _performSearch(search);
                    },
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}