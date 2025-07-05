import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class DocumentBackground extends StatelessWidget {
  final Size pageSize;
  final DocumentType documentType;

  const DocumentBackground({
    super.key,
    required this.pageSize,
    this.documentType = DocumentType.academic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: pageSize.width,
      height: pageSize.height,
      decoration: BoxDecoration(
        // Base paper color
        color: _getBaseColor(),
        
        // Paper texture gradient
        gradient: _getBackgroundGradient(),
        
        // Subtle border for realism
        border: Border.all(
          color: Colors.black.withOpacity(0.1),
          width: 0.5,
        ),
        
        // Slight shadow for depth
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Paper grain texture overlay
          _buildPaperTexture(),
          
          // Age spots and stains
          _buildAgeEffects(),
          
          // Document-specific elements
          _buildDocumentSpecificElements(),
        ],
      ),
    );
  }

  Color _getBaseColor() {
    switch (documentType) {
      case DocumentType.academic:
        return AppTheme.academicPaper;
      case DocumentType.personalLetter:
        return AppTheme.personalLetter;
      case DocumentType.policeReport:
        return AppTheme.policeReport;
      case DocumentType.journal:
        return AppTheme.journalPaper;
      case DocumentType.governmentMemo:
        return AppTheme.governmentMemo;
    }
  }

  LinearGradient _getBackgroundGradient() {
    switch (documentType) {
      case DocumentType.academic:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.academicPaper,
            AppTheme.academicPaperDark,
          ],
        );
      default:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getBaseColor(),
            _getBaseColor().withOpacity(0.9),
          ],
        );
    }
  }

  Widget _buildPaperTexture() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.15,
        child: Container(
          decoration: BoxDecoration(
            // Simulate paper fiber texture with a subtle pattern
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 2.0,
              colors: [
                Colors.brown.withOpacity(0.1),
                Colors.transparent,
                Colors.brown.withOpacity(0.05),
                Colors.transparent,
              ],
              stops: const [0.0, 0.25, 0.75, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgeEffects() {
    return Positioned.fill(
      child: Stack(
        children: [
          // Corner age spots
          Positioned(
            top: 8,
            right: 12,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.brown.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          Positioned(
            bottom: 15,
            left: 8,
            child: Container(
              width: 4,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.brown.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Subtle edge darkening
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.topRight,
                  colors: [
                    Colors.transparent,
                    Colors.brown.withOpacity(0.05),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSpecificElements() {
    switch (documentType) {
      case DocumentType.governmentMemo:
        return _buildClassifiedWatermark();
      case DocumentType.journal:
        return _buildJournalLines();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildClassifiedWatermark() {
    return Positioned.fill(
      child: Center(
        child: Transform.rotate(
          angle: -0.3,
          child: Opacity(
            opacity: 0.08,
            child: Text(
              'CLASSIFIED',
              style: TextStyle(
                fontSize: pageSize.width * 0.15,
                fontWeight: FontWeight.bold,
                color: AppTheme.classificationRed,
                letterSpacing: 8,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJournalLines() {
    return Positioned.fill(
      child: CustomPaint(
        painter: JournalLinesPainter(),
      ),
    );
  }
}

enum DocumentType {
  academic,
  personalLetter,
  policeReport,
  journal,
  governmentMemo,
}

class JournalLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..strokeWidth = 0.5;

    final lineSpacing = 24.0;
    final marginLeft = size.width * 0.12;
    final marginRight = size.width * 0.12;
    final startY = 40.0;

    // Draw horizontal lines
    for (double y = startY; y < size.height - 20; y += lineSpacing) {
      canvas.drawLine(
        Offset(marginLeft, y),
        Offset(size.width - marginRight, y),
        paint,
      );
    }

    // Draw margin line
    final marginPaint = Paint()
      ..color = Colors.red.withOpacity(0.4)
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(marginLeft + 30, 20),
      Offset(marginLeft + 30, size.height - 20),
      marginPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}