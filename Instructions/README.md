# Blackthorn Cursor Package

This is the full starter package for the interactive Blackthorn Manor Flutter app.

## Structure

- `content/`: All manuscript content in markdown format.
  - `front_matter.md`: Title, author, disclaimers, etc.
  - `manuscript/`: Chapters of the main story.
  - `back_matter.md`: Appendices, end notes, etc.
- `data/`: Structured metadata
  - `annotations.json`: Marginalia and post-it data
  - `redactions.json`: Redacted text definitions
  - `characters.json`: Character profiles and handwriting styles
- `assets/images/`: Placeholder folders for visual components
  - `backgrounds/`: Paper textures
  - `marginalia/`: Fixed handwriting
  - `stickers/`: Movable post-its

## Usage

Feed this directory into your Flutter project. This is the content layer for the rendering logic provided in your `DocumentPage` widgets.

Ensure assets are linked in `pubspec.yaml`.

