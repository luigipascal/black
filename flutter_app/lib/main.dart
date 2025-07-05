import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/document_state.dart';
import 'providers/access_provider.dart';
import 'screens/book_reader_screen.dart';
import 'constants/app_theme.dart';

void main() {
  runApp(const BlackthornManorApp());
}

class BlackthornManorApp extends StatelessWidget {
  const BlackthornManorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DocumentState()),
        ChangeNotifierProvider(create: (_) => AccessProvider()),
      ],
      child: MaterialApp(
        title: 'Blackthorn Manor Archive',
        theme: AppTheme.build(),
        home: const BookReaderScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}