#!/usr/bin/env python3
"""
Blackthorn Manor Content Processor
Converts raw chapter files and annotations into structured data for the Flutter app.
"""

import json
import os
import re
import sys
from pathlib import Path
from typing import Dict, List, Any, Optional
import random
from enum import Enum

class AnnotationType(Enum):
    MARGINALIA = "marginalia"
    POST_IT = "postIt"
    REDACTION = "redaction"
    STAMP = "stamp"

class AnnotationZone(Enum):
    LEFT_MARGIN = "leftMargin"
    RIGHT_MARGIN = "rightMargin"
    TOP_MARGIN = "topMargin"
    BOTTOM_MARGIN = "bottomMargin"
    CONTENT = "content"

class ContentProcessor:
    def __init__(self):
        self.chapters_dir = Path("content/chapters")
        self.data_dir = Path("content/data")
        self.output_dir = Path("flutter_app/assets/data")
        self.annotations = []
        self.chapters = []
    
    def run(self):
        """Main processing pipeline"""
        print("🏰 Processing Blackthorn Manor Content...")
        
        self.load_annotations()
        self.process_chapters()
        self.match_annotations_to_content()
        self.save_processed_data()
        self.generate_statistics()
        
        print("✅ Content processing completed successfully!")
    
    def load_annotations(self):
        """Load annotations from JSON file"""
        print("📂 Loading annotations...")
        
        annotations_file = self.data_dir / "annotations.json"
        if not annotations_file.exists():
            raise FileNotFoundError(f"Annotations file not found: {annotations_file}")
        
        with open(annotations_file, 'r', encoding='utf-8') as f:
            self.annotations = json.load(f)
        
        print(f"   📝 Loaded {len(self.annotations)} annotations")
    
    def process_chapters(self):
        """Process all chapter files"""
        print("📖 Processing chapters...")
        
        if not self.chapters_dir.exists():
            raise FileNotFoundError(f"Chapters directory not found: {self.chapters_dir}")
        
        # Get all markdown files and sort by chapter number
        chapter_files = list(self.chapters_dir.glob("*.md"))
        chapter_files.sort(key=self._extract_chapter_number)
        
        for file_path in chapter_files:
            chapter_data = self.process_chapter_file(file_path)
            self.chapters.append(chapter_data)
        
        print(f"   📚 Processed {len(self.chapters)} chapters")
    
    def _extract_chapter_number(self, file_path: Path) -> int:
        """Extract chapter number from filename"""
        match = re.search(r'CHAPTER_([IVX]+)', file_path.name)
        if match:
            return self._roman_to_int(match.group(1))
        return 999  # Put unmatched files at the end
    
    def _roman_to_int(self, roman: str) -> int:
        """Convert Roman numerals to integers"""
        roman_numerals = {'I': 1, 'V': 5, 'X': 10, 'L': 50, 'C': 100, 'D': 500, 'M': 1000}
        
        total = 0
        for i in range(len(roman)):
            current = roman_numerals.get(roman[i], 0)
            next_val = roman_numerals.get(roman[i + 1], 0) if i + 1 < len(roman) else 0
            
            if current < next_val:
                total -= current
            else:
                total += current
        
        return total
    
    def process_chapter_file(self, file_path: Path) -> Dict[str, Any]:
        """Process a single chapter file"""
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        chapter_name = file_path.stem
        
        # Split content into paragraphs
        paragraphs = [p.strip() for p in content.split('\n\n') if p.strip()]
        
        # Create pages from paragraphs (2-3 paragraphs per page)
        pages = []
        for i in range(0, len(paragraphs), 3):
            page_content = '\n\n'.join(paragraphs[i:i+3])
            pages.append({
                'pageNumber': len(pages) + 1,
                'chapterName': chapter_name,
                'content': page_content,
                'wordCount': len(page_content.split()),
                'annotations': []  # Will be populated later
            })
        
        return {
            'chapterNumber': self._extract_chapter_number(file_path),
            'chapterName': chapter_name,
            'filename': file_path.name,
            'fullContent': content,
            'pages': pages,
            'wordCount': len(content.split())
        }
    
    def match_annotations_to_content(self):
        """Match annotations to specific pages"""
        print("🔗 Matching annotations to content...")
        
        # Group annotations by chapter
        annotations_by_chapter = {}
        for annotation in self.annotations:
            chapter_name = annotation.get('chapter')
            if chapter_name:
                if chapter_name not in annotations_by_chapter:
                    annotations_by_chapter[chapter_name] = []
                annotations_by_chapter[chapter_name].append(annotation)
        
        # Distribute annotations across pages within each chapter
        for chapter in self.chapters:
            chapter_annotations = annotations_by_chapter.get(chapter['chapterName'], [])
            
            for i, annotation in enumerate(chapter_annotations):
                page_index = i % len(chapter['pages'])
                
                # Convert annotation to our format
                processed_annotation = {
                    'id': annotation['id'],
                    'character': self._parse_character(annotation['character']),
                    'text': annotation['text'],
                    'type': self._parse_annotation_type(annotation.get('type', 'marginalia')),
                    'year': annotation.get('year'),
                    'position': self._generate_position(annotation, page_index),
                    'chapterName': chapter['chapterName'],
                    'pageNumber': page_index + 1
                }
                
                chapter['pages'][page_index]['annotations'].append(processed_annotation)
        
        total_annotations = sum(len(ann) for ann in annotations_by_chapter.values())
        print(f"   🔗 Matched {total_annotations} annotations to content")
    
    def _parse_character(self, character) -> str:
        """Parse character field (can be string or list)"""
        if isinstance(character, list):
            return character[0] if character else "Unknown"
        return character or "Unknown"
    
    def _parse_annotation_type(self, type_str: str) -> str:
        """Parse annotation type"""
        type_mapping = {
            'marginalia': AnnotationType.MARGINALIA.value,
            'sticker': AnnotationType.POST_IT.value,
            'redaction': AnnotationType.REDACTION.value
        }
        return type_mapping.get(type_str.lower(), AnnotationType.MARGINALIA.value)
    
    def _generate_position(self, annotation: Dict[str, Any], page_index: int) -> Dict[str, Any]:
        """Generate position for annotation based on character and year"""
        # Use annotation ID as seed for consistent positioning
        random.seed(hash(annotation['id']))
        
        character = self._parse_character(annotation['character'])
        year = annotation.get('year')
        
        # Determine annotation zone based on year
        if year and year >= 2000:
            # Post-2000 annotations can be anywhere
            zones = list(AnnotationZone)
            zone = random.choice(zones)
        else:
            # Pre-2000 annotations only in margins
            margin_zones = [
                AnnotationZone.LEFT_MARGIN,
                AnnotationZone.RIGHT_MARGIN,
                AnnotationZone.TOP_MARGIN,
                AnnotationZone.BOTTOM_MARGIN
            ]
            zone = random.choice(margin_zones)
        
        # Generate position within the zone
        if zone == AnnotationZone.LEFT_MARGIN:
            x = 0.02 + random.random() * 0.08  # 2-10% from left
            y = 0.1 + random.random() * 0.8    # 10-90% from top
        elif zone == AnnotationZone.RIGHT_MARGIN:
            x = 0.9 + random.random() * 0.08   # 90-98% from left
            y = 0.1 + random.random() * 0.8    # 10-90% from top
        elif zone == AnnotationZone.TOP_MARGIN:
            x = 0.15 + random.random() * 0.7   # 15-85% from left
            y = 0.02 + random.random() * 0.08  # 2-10% from top
        elif zone == AnnotationZone.BOTTOM_MARGIN:
            x = 0.15 + random.random() * 0.7   # 15-85% from left
            y = 0.9 + random.random() * 0.08   # 90-98% from top
        else:  # CONTENT
            x = 0.2 + random.random() * 0.6    # 20-80% from left
            y = 0.15 + random.random() * 0.7   # 15-85% from top
        
        return {
            'zone': zone.value,
            'x': x,
            'y': y,
            'rotation': (random.random() - 0.5) * 0.1  # Small rotation
        }
    
    def save_processed_data(self):
        """Save processed data to JSON files"""
        print("💾 Saving processed data...")
        
        # Create output directory
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Save individual chapter data
        for chapter in self.chapters:
            chapter_file = self.output_dir / f"{chapter['chapterName']}.json"
            with open(chapter_file, 'w', encoding='utf-8') as f:
                json.dump(chapter, f, indent=2, ensure_ascii=False)
        
        # Save complete book data
        book_data = {
            'title': 'Blackthorn Manor: An Architectural Study',
            'author': 'Professor Harold Finch',
            'totalChapters': len(self.chapters),
            'totalPages': sum(len(chapter['pages']) for chapter in self.chapters),
            'totalAnnotations': len(self.annotations),
            'chapters': self.chapters
        }
        
        book_file = self.output_dir / "complete_book.json"
        with open(book_file, 'w', encoding='utf-8') as f:
            json.dump(book_data, f, indent=2, ensure_ascii=False)
        
        # Save character data
        character_data = self._generate_character_data()
        character_file = self.output_dir / "characters.json"
        with open(character_file, 'w', encoding='utf-8') as f:
            json.dump(character_data, f, indent=2, ensure_ascii=False)
        
        print(f"   💾 Saved processed data to {self.output_dir}")
    
    def _generate_character_data(self) -> Dict[str, Any]:
        """Generate character information data"""
        character_info = {
            'MB': {
                'name': 'Margaret Blackthorn',
                'fullName': 'Margaret Blackthorn',
                'years': '1930-1999',
                'description': 'Last surviving member of the Blackthorn family. Maintained the estate and its secrets until her death.',
                'role': 'Family Guardian',
                'annotationStyle': {
                    'fontFamily': 'Dancing Script',
                    'fontSize': 10,
                    'color': '#2653a3',
                    'fontStyle': 'italic',
                    'description': 'Elegant blue script'
                }
            },
            'JR': {
                'name': 'James Reed',
                'fullName': 'James Reed',
                'years': '1984-1990',
                'description': 'Independent researcher who investigated the manor\'s architectural anomalies. Disappeared in 1989.',
                'role': 'Researcher',
                'annotationStyle': {
                    'fontFamily': 'Kalam',
                    'fontSize': 9,
                    'color': '#1a1a1a',
                    'fontStyle': 'normal',
                    'description': 'Messy black ballpoint'
                }
            },
            'EW': {
                'name': 'Eliza Winston',
                'fullName': 'Eliza Winston',
                'years': '1995-1999',
                'description': 'Structural engineer commissioned to assess the building\'s safety. Her reports raised serious concerns.',
                'role': 'Engineer',
                'annotationStyle': {
                    'fontFamily': 'Architects Daughter',
                    'fontSize': 10,
                    'color': '#c41e3a',
                    'fontStyle': 'normal',
                    'description': 'Precise red pen'
                }
            },
            'SW': {
                'name': 'Simon Wells',
                'fullName': 'Simon Wells',
                'years': '2024+',
                'description': 'Current investigator exploring the manor\'s mysteries. His sister Claire also disappeared.',
                'role': 'Current Investigator',
                'annotationStyle': {
                    'fontFamily': 'Kalam',
                    'fontSize': 9,
                    'color': '#2c2c2c',
                    'fontStyle': 'normal',
                    'description': 'Hurried pencil'
                }
            },
            'Detective Sharma': {
                'name': 'Detective Sharma',
                'fullName': 'Detective Moira Sharma',
                'years': '2024+',
                'description': 'County Police detective investigating the disappearances at Blackthorn Manor.',
                'role': 'Police Investigator',
                'annotationStyle': {
                    'fontFamily': 'Courier Prime',
                    'fontSize': 8,
                    'color': '#006400',
                    'fontStyle': 'normal',
                    'description': 'Official green ink'
                }
            },
            'Dr. Chambers': {
                'name': 'Dr. Chambers',
                'fullName': 'Dr. E. Chambers',
                'years': '2024+',
                'description': 'Government analyst with Department 8, specializing in anomalous phenomena.',
                'role': 'Government Analyst',
                'annotationStyle': {
                    'fontFamily': 'Courier Prime',
                    'fontSize': 8,
                    'color': '#000000',
                    'fontStyle': 'normal',
                    'description': 'Official black ink'
                }
            }
        }
        
        return {
            'characters': character_info,
            'temporalRules': {
                'pre2000': {
                    'allowedTypes': ['marginalia'],
                    'allowedZones': ['leftMargin', 'rightMargin', 'topMargin', 'bottomMargin'],
                    'description': 'Pre-2000 annotations are fixed in margins only'
                },
                'post2000': {
                    'allowedTypes': ['postIt', 'sticker'],
                    'allowedZones': ['leftMargin', 'rightMargin', 'topMargin', 'bottomMargin', 'content'],
                    'description': 'Post-2000 annotations can be placed anywhere and are draggable'
                }
            }
        }
    
    def generate_statistics(self):
        """Generate and print content statistics"""
        print("📊 Generating statistics...")
        
        total_pages = sum(len(chapter['pages']) for chapter in self.chapters)
        total_words = sum(chapter['wordCount'] for chapter in self.chapters)
        total_annotations = len(self.annotations)
        
        # Character statistics
        character_stats = {}
        for annotation in self.annotations:
            character = self._parse_character(annotation['character'])
            character_stats[character] = character_stats.get(character, 0) + 1
        
        # Year statistics
        year_stats = {}
        for annotation in self.annotations:
            year = annotation.get('year')
            if year:
                decade = f"{(year // 10) * 10}s"
                year_stats[decade] = year_stats.get(decade, 0) + 1
        
        print("\n📊 CONTENT STATISTICS")
        print(f"   📚 Total Chapters: {len(self.chapters)}")
        print(f"   📄 Total Pages: {total_pages}")
        print(f"   🔤 Total Words: {total_words:,}")
        print(f"   📝 Total Annotations: {total_annotations}")
        print(f"   📖 Average Words per Page: {total_words // total_pages if total_pages > 0 else 0}")
        print(f"   📎 Average Annotations per Page: {total_annotations / total_pages:.1f}" if total_pages > 0 else "   📎 Average Annotations per Page: 0")
        
        print("\n👥 CHARACTER BREAKDOWN:")
        for character, count in sorted(character_stats.items(), key=lambda x: x[1], reverse=True):
            print(f"   {character}: {count} annotations")
        
        print("\n📅 TEMPORAL DISTRIBUTION:")
        for decade, count in sorted(year_stats.items()):
            print(f"   {decade}: {count} annotations")

def main():
    """Main entry point"""
    try:
        processor = ContentProcessor()
        processor.run()
    except Exception as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()