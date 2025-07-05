import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'RedactableText.dart';
import 'DraggableMarginalia.dart';

class PageWidget extends StatelessWidget {
  final int pageNumber;
  const PageWidget(this.pageNumber, {super.key});

  @override
  Widget build(BuildContext context) {
    final themeFonts = Theme.of(context).textTheme;

    return InteractiveViewer(
      minScale: 1,
      maxScale: 3,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: RichText(
              text: TextSpan(
                style: themeFonts.bodyLarge,
                children: [
                  const TextSpan(text: 'An architectural survey of the eastern wing reveals '),
                  WidgetSpan(
                    child: RedactableText(
                      secret: 'a non-Euclidean antechamber unseen on blueprints',
                      placeholder: '███',
                      unlockKey: 'ch3_1',
                    ),
                  ),
                  const TextSpan(text: ' and a staircase descending at a 7° angle.'),
                ],
              ),
            ),
          ),
          DraggableMarginalia(
            id: 'mb_1976_p1',
            initialPos: const Offset(40, 80),
            child: Text(
              'He never understood the corridor’s true function. –MB, 1976',
              style: GoogleFonts.dancingScript(color: Color(0xff2653a3)),
            ),
          ),
          DraggableMarginalia(
            id: 'ew_1995_p1',
            initialPos: const Offset(250, 370),
            child: Text(
              'Redacted due to exposure risk. –EW, 1995',
              style: GoogleFonts.courierPrime(color: Color(0xffa11212)),
            ),
          ),
        ],
      ),
    );
  }
}