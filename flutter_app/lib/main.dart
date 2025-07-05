import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/enhanced_revelation_provider.dart';
import 'screens/enhanced_book_reader_screen.dart';
import 'screens/enhanced_character_timeline_screen.dart';
import 'screens/advanced_character_discovery_screen.dart';
import 'screens/advanced_features_demo_screen.dart';
import 'widgets/advanced_book_reader_widget.dart';
import 'constants/app_theme.dart';
import 'services/content_loading_service.dart';
import 'models/enhanced_document_models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences for persistent user progress
  final prefs = await SharedPreferences.getInstance();
  
  runApp(BlackthornManorApp(prefs: prefs));
}

class BlackthornManorApp extends StatelessWidget {
  final SharedPreferences prefs;
  
  const BlackthornManorApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => EnhancedRevelationProvider(prefs: prefs),
        ),
      ],
      child: MaterialApp(
        title: 'Blackthorn Manor Archive',
        theme: AppTheme.build(),
        home: const MainNavigationScreen(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/book_reader': (context) => const AdvancedBookReaderWidget(),
          '/character_timeline': (context) => const EnhancedCharacterTimelineScreen(),
          '/character_discovery': (context) => const AdvancedCharacterDiscoveryScreen(),
        },
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const AdvancedBookReaderWidget(),
    const AdvancedCharacterDiscoveryScreen(),
    const EnhancedCharacterTimelineScreen(),
  ];
  
  final List<String> _titles = [
    'Blackthorn Manor Archive',
    'Character Discovery',
    'Timeline & Events',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedRevelationProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: _screens[_currentIndex],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: provider.currentRevelationLevel == RevealLevel.completeTruth
                  ? Colors.purple
                  : Colors.blue,
              unselectedItemColor: Colors.grey,
              backgroundColor: Colors.white,
              elevation: 0,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.book_outlined),
                  activeIcon: Icon(Icons.book),
                  label: 'Archive',
                ),
                BottomNavigationBarItem(
                  icon: Stack(
                    children: [
                      const Icon(Icons.people_outline),
                      if (provider.characters.values.any((c) => c.isMissing))
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.all(Radius.circular(6)),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: const Text(
                              '!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  activeIcon: Stack(
                    children: [
                      const Icon(Icons.people),
                      if (provider.characters.values.any((c) => c.isMissing))
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.all(Radius.circular(6)),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: const Text(
                              '!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: 'Characters',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.timeline_outlined),
                  activeIcon: Icon(Icons.timeline),
                  label: 'Timeline',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}