import 'package:flutter/material.dart';

import '../models/document_models.dart';

class AppTheme {
  // Color Palette
  static const Color bookCover = Color(0xFF654321);
  static const Color bookSpine = Color(0xFF8B4513);
  static const Color academicPaper = Color(0xFFF4E8D0);
  static const Color academicPaperDark = Color(0xFFE8DCC0);
  static const Color personalLetter = Color(0xFFFFFFF0);
  static const Color policeReport = Color(0xFFF8F8FF);
  static const Color journalPaper = Color(0xFFFFFFF0);
  static const Color governmentMemo = Color(0xFFF5F5DC);

  // Annotation Colors
  static const Color marginaliaBlue = Color(0xFF2653a3);
  static const Color marginaliaBlack = Color(0xFF1a1a1a);
  static const Color marginaliaRed = Color(0xFFc41e3a);

  // Post-it Colors
  static const Color postItYellow = Color(0xFFFFFF99);
  static const Color postItWhite = Color(0xFFFFFFFF);
  static const Color postItManila = Color(0xFFF5F5DC);

  // UI Colors
  static const Color redactionBlack = Color(0xFF000000);
  static const Color classificationRed = Color(0xFFd32f2f);

  static ThemeData build() {
    return ThemeData(
      useMaterial3: true,
      primarySwatch: Colors.brown,
      scaffoldBackgroundColor: bookCover,
      
      // Typography
      textTheme: _buildTextTheme(),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: bookSpine,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      
      // Card Theme
      cardTheme: CardTheme(
        color: academicPaper,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      
      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: bookSpine,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      
      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: academicPaper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return const TextTheme(
      // Main document text
      bodyLarge: TextStyle(
        fontFamily: 'Courier Prime',
        fontSize: 12,
        height: 1.4,
        color: Color(0xFF2a2a2a),
        fontWeight: FontWeight.normal,
      ),
      
      bodyMedium: TextStyle(
        fontFamily: 'Courier Prime',
        fontSize: 11,
        height: 1.3,
        color: Color(0xFF2a2a2a),
      ),
      
      // Chapter headings
      headlineLarge: TextStyle(
        fontFamily: 'Courier Prime',
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1a1a1a),
      ),
      
      headlineMedium: TextStyle(
        fontFamily: 'Courier Prime',
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1a1a1a),
      ),
      
      // UI text
      titleLarge: TextStyle(
        fontFamily: 'Courier Prime',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      
      titleMedium: TextStyle(
        fontFamily: 'Courier Prime',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1a1a1a),
      ),
      
      labelLarge: TextStyle(
        fontFamily: 'Courier Prime',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      
      // Page numbers
      labelSmall: TextStyle(
        fontFamily: 'Courier Prime',
        fontSize: 10,
        color: Color(0xFF666666),
      ),
    );
  }
}

class CharacterStyles {
  // Margaret Blackthorn - Elegant blue script
  static const TextStyle margaretBlackthorn = TextStyle(
    fontFamily: 'Dancing Script',
    fontSize: 10,
    color: AppTheme.marginaliaBlue,
    fontStyle: FontStyle.italic,
  );

  // James Reed - Messy black ballpoint
  static const TextStyle jamesReed = TextStyle(
    fontFamily: 'Kalam',
    fontSize: 9,
    color: AppTheme.marginaliaBlack,
  );

  // Eliza Winston - Precise red pen
  static const TextStyle elizaWinston = TextStyle(
    fontFamily: 'Architects Daughter',
    fontSize: 10,
    color: AppTheme.marginaliaRed,
    fontWeight: FontWeight.w500,
  );

  // Simon Wells - Hurried pencil
  static const TextStyle simonWells = TextStyle(
    fontFamily: 'Kalam',
    fontSize: 9,
    color: Color(0xFF2c2c2c),
  );

  // Detective Sharma - Official green ink
  static const TextStyle detectiveSharma = TextStyle(
    fontFamily: 'Courier Prime',
    fontSize: 8,
    color: Color(0xFF006400),
    fontWeight: FontWeight.w500,
  );

  // Dr. Chambers - Official black ink
  static const TextStyle drChambers = TextStyle(
    fontFamily: 'Courier Prime',
    fontSize: 8,
    color: Colors.black,
  );

  static TextStyle getStyleForCharacter(String character) {
    switch (character) {
      case 'MB':
        return margaretBlackthorn;
      case 'JR':
        return jamesReed;
      case 'EW':
        return elizaWinston;
      case 'SW':
        return simonWells;
      case 'Detective Sharma':
        return detectiveSharma;
      case 'Dr. Chambers':
        return drChambers;
      default:
        return const TextStyle(
          fontFamily: 'Courier Prime',
          fontSize: 10,
          color: Colors.black87,
        );
    }
  }
}

class PageDimensions {
  static const double aspectRatio = 11.0 / 8.5; // US Letter
  static const double marginRatio = 0.12; // 12% margin on each side
  static const double spineWidth = 24.0;
  static const double pageSpacing = 8.0;
  static const int maxAnnotationsPerPage = 8; // Performance limit

  static Size calculatePageSize(BuildContext context, ReadingMode readingMode) {
    final screenSize = MediaQuery.of(context).size;
    
    switch (readingMode) {
      case ReadingMode.singlePage:
        final maxWidth = screenSize.width * 0.9;
        final maxHeight = screenSize.height * 0.85;
        
        final widthConstrainedHeight = maxWidth * aspectRatio;
        if (widthConstrainedHeight <= maxHeight) {
          return Size(maxWidth, widthConstrainedHeight);
        } else {
          return Size(maxHeight / aspectRatio, maxHeight);
        }
        
      case ReadingMode.bookSpread:
        final availableWidth = screenSize.width - spineWidth - (pageSpacing * 2);
        final pageWidth = availableWidth / 2;
        final pageHeight = pageWidth * aspectRatio;
        
        // Ensure it fits on screen
        final maxHeight = screenSize.height * 0.85;
        if (pageHeight > maxHeight) {
          final adjustedHeight = maxHeight;
          final adjustedWidth = adjustedHeight / aspectRatio;
          return Size(adjustedWidth, adjustedHeight);
        }
        
        return Size(pageWidth, pageHeight);
    }
  }

  static EdgeInsets getPageMargins(Size pageSize) {
    final marginSize = pageSize.width * marginRatio;
    return EdgeInsets.all(marginSize);
  }
}