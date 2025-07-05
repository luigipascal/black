#!/usr/bin/env python3
"""
Enhanced Blackthorn Manor Content Processor
Handles redacted content, embedded annotations, progressive revelation, and character story arcs.
"""

import json
import os
import re
import sys
from pathlib import Path
from typing import Dict, List, Any, Optional, Tuple
import random
from enum import Enum
from datetime import datetime

class AnnotationType(Enum):
    MARGINALIA = "marginalia"
    POST_IT = "postIt"
    REDACTION = "redaction"
    STAMP = "stamp"
    HIDDEN = "hidden"

class AnnotationZone(Enum):
    LEFT_MARGIN = "leftMargin"
    RIGHT_MARGIN = "rightMargin"
    TOP_MARGIN = "topMargin"
    BOTTOM_MARGIN = "bottomMargin"
    CONTENT = "content"

class RevealLevel(Enum):
    ACADEMIC = 1      # Original academic text only
    FAMILY_SECRETS = 2    # Margaret's annotations visible
    INVESTIGATION = 3     # Research notes appear
    MODERN_MYSTERY = 4    # Current investigation
    COMPLETE_TRUTH = 5    # Full supernatural revelation

class EnhancedContentProcessor:
    def __init__(self):
        self.chapters_dir = Path("content/chapters")
        self.data_dir = Path("content/data")
        self.output_dir = Path("flutter_app/assets/data")
        self.web_output_dir = Path("web_app/data")
        
        self.annotations = []
        self.chapters = []
        self.characters = {}
        self.redacted_content = []
        self.character_timeline = {}
        
        # Character annotation patterns
        self.character_patterns = {
            "MB": r"\[Elegant blue script\](.*?)-MB, (\d{4})",
            "JR": r"\[Messy black ballpoint\](.*?)-JR, (\d{4})",
            "EW": r"\[Precise red pen\](.*?)-EW, (\d{4})",
            "SW": r"\[Hurried pencil\](.*?)-SW, (\w+\s+\d+,\s+\d{4})",
            "Detective Sharma": r"\[Detective's green ink\](.*?)Detective [A-Za-z]+ Sharma",
            "Dr. Chambers": r"\[Official black ink\](.*?)-Dr\. Chambers"
        }
        
        # Redaction patterns
        self.redaction_patterns = [
            r"\[REDACTED\]",
            r"\[CLASSIFIED\]",
            r"\[DATA EXPUNGED\]",
            r"\[REMOVED BY ORDER OF\]",
        ]
    
    def run(self):
        """Enhanced processing pipeline"""
        print("🏰 Enhanced Blackthorn Manor Content Processing...")
        
        self.load_annotations()
        self.process_all_chapters()
        self.extract_embedded_annotations()
        self.process_redacted_content()
        self.create_character_timelines()
        self.generate_progressive_revelation()
        self.save_enhanced_data()
        self.create_web_app_data()
        self.generate_comprehensive_statistics()
        
        print("✅ Enhanced content processing completed successfully!")
    
    def load_annotations(self):
        """Load and categorize all annotations"""
        print("📂 Loading and categorizing annotations...")
        
        annotations_file = self.data_dir / "annotations.json"
        if not annotations_file.exists():
            raise FileNotFoundError(f"Annotations file not found: {annotations_file}")
        
        with open(annotations_file, 'r', encoding='utf-8') as f:
            raw_annotations = json.load(f)
        
        # Process and categorize annotations
        for ann in raw_annotations:
            processed_ann = self.process_single_annotation(ann)
            if processed_ann:
                self.annotations.append(processed_ann)
        
        print(f"   📝 Processed {len(self.annotations)} annotations")
    
    def process_single_annotation(self, annotation: Dict) -> Dict:
        """Process a single annotation with enhanced metadata"""
        character = self._parse_character(annotation.get('character', []))
        text = annotation.get('text', '')
        year = annotation.get('year')
        
        # Determine annotation type and reveal level
        reveal_level = self._determine_reveal_level(character, year, text)
        annotation_type = self._determine_annotation_type(text, year)
        
        # Check for embedded redacted content
        redacted_parts = self._extract_redacted_content(text)
        
        return {
            'id': annotation.get('id', f"ann_{len(self.annotations)}"),
            'character': character,
            'text': text,
            'type': annotation_type,
            'year': year,
            'chapter': annotation.get('chapter'),
            'revealLevel': reveal_level.value,
            'redactedParts': redacted_parts,
            'characterStyle': self._get_character_style(character),
            'isEmbedded': self._is_embedded_annotation(text),
            'unlockConditions': self._generate_unlock_conditions(character, year, text)
        }
    
    def process_all_chapters(self):
        """Process all chapter files with enhanced features"""
        print("📖 Processing all chapters with enhanced features...")
        
        if not self.chapters_dir.exists():
            raise FileNotFoundError(f"Chapters directory not found: {self.chapters_dir}")
        
        chapter_files = list(self.chapters_dir.glob("*.md"))
        chapter_files.sort(key=self._extract_chapter_number)
        
        for file_path in chapter_files:
            chapter_data = self.process_chapter_file_enhanced(file_path)
            self.chapters.append(chapter_data)
        
        print(f"   📚 Processed {len(self.chapters)} chapters into {sum(len(ch['pages']) for ch in self.chapters)} pages")
    
    def process_chapter_file_enhanced(self, file_path: Path) -> Dict[str, Any]:
        """Enhanced chapter processing with embedded content extraction"""
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        chapter_name = file_path.stem
        chapter_number = self._extract_chapter_number(file_path)
        
        # Extract embedded annotations from content
        embedded_annotations = self._extract_embedded_annotations(content, chapter_name)
        
        # Process redacted content within the main text
        content_with_redactions = self._process_text_redactions(content)
        
        # Split content into pages (optimized for readability)
        pages = self._create_optimized_pages(content_with_redactions, chapter_name, embedded_annotations)
        
        return {
            'chapterNumber': chapter_number,
            'chapterName': chapter_name,
            'filename': file_path.name,
            'fullContent': content,
            'pages': pages,
            'wordCount': len(content.split()),
            'embeddedAnnotations': embedded_annotations,
            'hasRedactedContent': len([p for p in pages if p.get('redactedSections', [])]) > 0
        }
    
    def _extract_embedded_annotations(self, content: str, chapter_name: str) -> List[Dict]:
        """Extract annotations embedded directly in the text"""
        embedded_annotations = []
        
        for character, pattern in self.character_patterns.items():
            matches = re.finditer(pattern, content, re.DOTALL | re.IGNORECASE)
            for match in matches:
                annotation_text = match.group(1).strip()
                year_str = match.group(2) if len(match.groups()) > 1 else None
                
                # Parse year from various formats
                year = self._parse_year(year_str) if year_str else None
                
                embedded_annotations.append({
                    'id': f"emb_{len(embedded_annotations)}_{character}",
                    'character': character,
                    'text': annotation_text,
                    'year': year,
                    'chapter': chapter_name,
                    'type': 'marginalia' if year and year < 2000 else 'postIt',
                    'isEmbedded': True,
                    'revealLevel': self._determine_reveal_level(character, year, annotation_text).value
                })
        
        return embedded_annotations
    
    def _create_optimized_pages(self, content: str, chapter_name: str, embedded_annotations: List[Dict]) -> List[Dict]:
        """Create pages optimized for reading experience"""
        pages = []
        
        # Split content into paragraphs
        paragraphs = [p.strip() for p in content.split('\n\n') if p.strip()]
        
        # Determine optimal page breaks (aim for 150-250 words per page)
        current_page_content = []
        current_word_count = 0
        page_number = len([p for ch in self.chapters for p in ch.get('pages', [])]) + 1
        
        for paragraph in paragraphs:
            paragraph_words = len(paragraph.split())
            
            # Check if adding this paragraph would exceed optimal page length
            if current_word_count + paragraph_words > 250 and current_page_content:
                # Create page with current content
                page_content = '\n\n'.join(current_page_content)
                page_annotations = self._assign_annotations_to_page(page_number, chapter_name, embedded_annotations)
                
                pages.append({
                    'pageNumber': page_number,
                    'chapterName': chapter_name,
                    'content': page_content,
                    'wordCount': current_word_count,
                    'annotations': page_annotations,
                    'annotationCount': len(page_annotations),
                    'redactedSections': self._find_redacted_sections(page_content),
                    'revealLevels': self._calculate_page_reveal_levels(page_annotations),
                    'hasEmbeddedContent': len([a for a in page_annotations if a.get('isEmbedded')]) > 0
                })
                
                # Start new page
                current_page_content = [paragraph]
                current_word_count = paragraph_words
                page_number += 1
            else:
                current_page_content.append(paragraph)
                current_word_count += paragraph_words
        
        # Create final page if there's remaining content
        if current_page_content:
            page_content = '\n\n'.join(current_page_content)
            page_annotations = self._assign_annotations_to_page(page_number, chapter_name, embedded_annotations)
            
            pages.append({
                'pageNumber': page_number,
                'chapterName': chapter_name,
                'content': page_content,
                'wordCount': current_word_count,
                'annotations': page_annotations,
                'annotationCount': len(page_annotations),
                'redactedSections': self._find_redacted_sections(page_content),
                'revealLevels': self._calculate_page_reveal_levels(page_annotations),
                'hasEmbeddedContent': len([a for a in page_annotations if a.get('isEmbedded')]) > 0
            })
        
        return pages
    
    def _assign_annotations_to_page(self, page_number: int, chapter_name: str, embedded_annotations: List[Dict]) -> List[Dict]:
        """Assign annotations to specific pages with enhanced positioning"""
        page_annotations = []
        
        # Add embedded annotations for this chapter
        chapter_embedded = [a for a in embedded_annotations if a['chapter'] == chapter_name]
        
        # Distribute embedded annotations across pages in this chapter
        if chapter_embedded:
            annotations_per_page = min(len(chapter_embedded), 8)  # Max 8 per page
            for i, annotation in enumerate(chapter_embedded[:annotations_per_page]):
                positioned_annotation = self._create_positioned_annotation(annotation, page_number, i)
                page_annotations.append(positioned_annotation)
        
        # Add regular annotations from the JSON file
        chapter_annotations = [a for a in self.annotations 
                             if a.get('chapter') == chapter_name and not a.get('isEmbedded')]
        
        # Distribute regular annotations
        remaining_slots = 8 - len(page_annotations)
        if chapter_annotations and remaining_slots > 0:
            selected_annotations = chapter_annotations[:remaining_slots]
            for i, annotation in enumerate(selected_annotations):
                positioned_annotation = self._create_positioned_annotation(annotation, page_number, len(page_annotations) + i)
                page_annotations.append(positioned_annotation)
        
        return page_annotations
    
    def _create_positioned_annotation(self, annotation: Dict, page_number: int, index: int) -> Dict:
        """Create annotation with enhanced positioning and metadata"""
        # Use annotation ID as seed for consistent positioning
        random.seed(hash(annotation['id']))
        
        character = annotation['character']
        year = annotation.get('year')
        annotation_type = annotation.get('type', 'marginalia')
        
        # Determine position based on character, year, and index
        position = self._generate_enhanced_position(character, year, annotation_type, index)
        
        return {
            **annotation,
            'pageNumber': page_number,
            'position': position,
            'style': self._get_character_style(character),
            'isDraggable': annotation_type == 'postIt' or (year and year >= 2000),
            'revealLevel': annotation.get('revealLevel', RevealLevel.ACADEMIC.value),
            'characterArc': self._get_character_arc_stage(character, year),
            'relatedAnnotations': self._find_related_annotations(annotation)
        }
    
    def _generate_enhanced_position(self, character: str, year: Optional[int], annotation_type: str, index: int) -> Dict:
        """Generate enhanced positioning with character-specific preferences"""
        
        # Character positioning preferences
        character_zones = {
            'MB': [AnnotationZone.RIGHT_MARGIN, AnnotationZone.TOP_MARGIN],  # Margaret prefers right side
            'JR': [AnnotationZone.LEFT_MARGIN, AnnotationZone.BOTTOM_MARGIN],  # James prefers left side
            'EW': [AnnotationZone.RIGHT_MARGIN, AnnotationZone.CONTENT],  # Eliza uses precise positioning
            'SW': [AnnotationZone.LEFT_MARGIN, AnnotationZone.CONTENT],  # Simon uses available space
            'Detective Sharma': [AnnotationZone.TOP_MARGIN, AnnotationZone.BOTTOM_MARGIN],  # Official notes
            'Dr. Chambers': [AnnotationZone.BOTTOM_MARGIN, AnnotationZone.RIGHT_MARGIN]  # Government style
        }
        
        # Determine zone
        preferred_zones = character_zones.get(character, list(AnnotationZone))
        if year and year >= 2000:
            # Post-2000 annotations can go anywhere
            zone = random.choice(list(AnnotationZone))
        else:
            # Pre-2000 limited to margins
            margin_zones = [z for z in preferred_zones if 'margin' in z.value.lower()]
            zone = random.choice(margin_zones) if margin_zones else random.choice(preferred_zones)
        
        # Generate position within zone
        if zone == AnnotationZone.LEFT_MARGIN:
            x = 0.01 + (index % 3) * 0.02  # Stagger multiple annotations
            y = 0.1 + random.random() * 0.7
        elif zone == AnnotationZone.RIGHT_MARGIN:
            x = 0.85 + (index % 3) * 0.02
            y = 0.1 + random.random() * 0.7
        elif zone == AnnotationZone.TOP_MARGIN:
            x = 0.15 + random.random() * 0.6
            y = 0.01 + (index % 3) * 0.02
        elif zone == AnnotationZone.BOTTOM_MARGIN:
            x = 0.15 + random.random() * 0.6
            y = 0.85 + (index % 3) * 0.02
        else:  # CONTENT
            x = 0.2 + random.random() * 0.5
            y = 0.15 + random.random() * 0.6
        
        # Character-specific rotation
        rotation_preferences = {
            'MB': (-0.05, 0.05),    # Slight elegant tilt
            'JR': (-0.15, 0.15),    # Messy rotation
            'EW': (-0.02, 0.02),    # Very precise
            'SW': (-0.1, 0.1),      # Natural handwriting tilt
        }
        
        rotation_range = rotation_preferences.get(character, (-0.1, 0.1))
        rotation = random.uniform(*rotation_range)
        
        return {
            'zone': zone.value,
            'x': x,
            'y': y,
            'rotation': rotation
        }
    
    def create_character_timelines(self):
        """Create comprehensive character timelines and story arcs"""
        print("👥 Creating character timelines and story arcs...")
        
        for character in ['MB', 'JR', 'EW', 'SW', 'Detective Sharma', 'Dr. Chambers']:
            character_annotations = [a for a in self.annotations if a['character'] == character]
            character_annotations.sort(key=lambda x: x.get('year', 1967))
            
            timeline = {
                'character': character,
                'fullName': self._get_character_full_name(character),
                'role': self._get_character_role(character),
                'timeline': character_annotations,
                'storyArc': self._generate_story_arc(character, character_annotations),
                'mysteryInvolvement': self._analyze_mystery_involvement(character, character_annotations),
                'disappearanceClues': self._find_disappearance_clues(character, character_annotations)
            }
            
            self.character_timeline[character] = timeline
    
    def generate_progressive_revelation(self):
        """Generate progressive revelation system"""
        print("🔓 Generating progressive revelation system...")
        
        self.revelation_system = {
            'revealLevels': {
                1: {
                    'name': 'Academic Study',
                    'description': 'Original Professor Finch architectural study',
                    'visibleContent': ['academic_text'],
                    'hiddenContent': ['all_annotations', 'redacted_sections']
                },
                2: {
                    'name': 'Family Secrets',
                    'description': 'Margaret Blackthorn\'s family knowledge revealed',
                    'visibleContent': ['academic_text', 'mb_annotations'],
                    'hiddenContent': ['research_annotations', 'modern_annotations', 'redacted_sections']
                },
                3: {
                    'name': 'Research Investigation',
                    'description': 'James Reed and Eliza Winston\'s findings',
                    'visibleContent': ['academic_text', 'mb_annotations', 'jr_annotations', 'ew_annotations'],
                    'hiddenContent': ['modern_annotations', 'partial_redacted_sections']
                },
                4: {
                    'name': 'Modern Mystery',
                    'description': 'Current investigation and disappearances',
                    'visibleContent': ['all_annotations'],
                    'hiddenContent': ['classified_redactions']
                },
                5: {
                    'name': 'Complete Truth',
                    'description': 'Full supernatural revelation',
                    'visibleContent': ['everything'],
                    'hiddenContent': []
                }
            },
            'unlockConditions': self._generate_unlock_conditions_system(),
            'characterProgression': self._generate_character_progression_system()
        }
    
    def save_enhanced_data(self):
        """Save all enhanced data structures"""
        print("💾 Saving enhanced data structures...")
        
        # Create output directories
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Save complete enhanced book data
        enhanced_book_data = {
            'title': 'Blackthorn Manor: An Architectural Study',
            'subtitle': 'Enhanced Interactive Edition',
            'author': 'Professor Harold Finch',
            'version': '2.0.0-enhanced',
            'totalChapters': len(self.chapters),
            'totalPages': sum(len(chapter['pages']) for chapter in self.chapters),
            'totalAnnotations': len(self.annotations),
            'chapters': self.chapters,
            'characterTimelines': self.character_timeline,
            'revelationSystem': self.revelation_system,
            'redactedContent': self.redacted_content,
            'metadata': {
                'processingDate': datetime.now().isoformat(),
                'enhancedFeatures': [
                    'progressive_revelation',
                    'character_timelines',
                    'redacted_content',
                    'embedded_annotations',
                    'missing_persons_mystery'
                ]
            }
        }
        
        # Save main book file
        with open(self.output_dir / "enhanced_complete_book.json", 'w', encoding='utf-8') as f:
            json.dump(enhanced_book_data, f, indent=2, ensure_ascii=False)
        
        # Save character data
        enhanced_characters = self._generate_enhanced_character_data()
        with open(self.output_dir / "enhanced_characters.json", 'w', encoding='utf-8') as f:
            json.dump(enhanced_characters, f, indent=2, ensure_ascii=False)
        
        print(f"   💾 Saved enhanced data to {self.output_dir}")
    
    # Helper methods for enhanced processing
    def _determine_reveal_level(self, character: str, year: Optional[int], text: str) -> RevealLevel:
        """Determine at what level this content should be revealed"""
        if not year or year < 1970:
            return RevealLevel.ACADEMIC
        elif character == 'MB':
            return RevealLevel.FAMILY_SECRETS
        elif character in ['JR', 'EW']:
            return RevealLevel.INVESTIGATION
        elif character in ['SW', 'Detective Sharma', 'Dr. Chambers']:
            return RevealLevel.MODERN_MYSTERY
        elif 'supernatural' in text.lower() or 'entity' in text.lower():
            return RevealLevel.COMPLETE_TRUTH
        else:
            return RevealLevel.ACADEMIC
    
    def _determine_annotation_type(self, text: str, year: Optional[int]) -> str:
        """Determine annotation type based on content and year"""
        if year and year >= 2000:
            return 'postIt'
        elif any(pattern in text.upper() for pattern in ['REDACTED', 'CLASSIFIED']):
            return 'redaction'
        else:
            return 'marginalia'
    
    def _get_character_style(self, character: str) -> str:
        """Get character-specific styling class"""
        style_map = {
            'MB': 'character-mb elegant-blue-script',
            'JR': 'character-jr messy-black-ballpoint',
            'EW': 'character-ew precise-red-pen',
            'SW': 'character-sw hurried-pencil',
            'Detective Sharma': 'character-detective green-ink-official',
            'Dr. Chambers': 'character-chambers official-black-ink'
        }
        return style_map.get(character, 'character-unknown')
    
    def _extract_redacted_content(self, text: str) -> List[Dict]:
        """Extract redacted content with reveal conditions"""
        redacted_parts = []
        for pattern in self.redaction_patterns:
            matches = re.finditer(pattern, text)
            for match in matches:
                redacted_parts.append({
                    'position': match.span(),
                    'hiddenText': match.group(0),
                    'revealedText': self._generate_revealed_text(match.group(0)),
                    'revealLevel': RevealLevel.COMPLETE_TRUTH.value
                })
        return redacted_parts
    
    def _generate_revealed_text(self, redacted_text: str) -> str:
        """Generate appropriate revealed text for redacted content"""
        reveal_map = {
            '[REDACTED]': 'dimensional entities',
            '[CLASSIFIED]': 'supernatural manifestations',
            '[DATA EXPUNGED]': 'The Watchers',
            '[REMOVED BY ORDER OF]': 'Department 8 - Anomalous Phenomena Division'
        }
        return reveal_map.get(redacted_text, 'classified information')
    
         # Additional helper methods...
     def _is_embedded_annotation(self, text: str) -> bool:
         """Check if annotation is embedded in text with formatting markers"""
         return any(marker in text for marker in ['[Elegant blue script]', '[Messy black ballpoint]', '[Precise red pen]', '[Hurried pencil]'])
     
     def _generate_unlock_conditions(self, character: str, year: Optional[int], text: str) -> List[str]:
         """Generate unlock conditions for this annotation"""
         conditions = []
         if character == 'MB':
             conditions.append('family_secrets_unlocked')
         elif character in ['JR', 'EW']:
             conditions.append('research_phase_unlocked')
         elif character in ['SW', 'Detective Sharma']:
             conditions.append('modern_mystery_unlocked')
         if year and year >= 2020:
             conditions.append('current_investigation_active')
         return conditions
     
     def _process_text_redactions(self, content: str) -> str:
         """Process redacted content in main text"""
         for pattern in self.redaction_patterns:
             content = re.sub(pattern, f'<span class="redacted" data-reveal="{self._generate_revealed_text(pattern)}">{pattern}</span>', content)
         return content
     
     def _find_redacted_sections(self, page_content: str) -> List[Dict]:
         """Find redacted sections within page content"""
         redacted = []
         for pattern in self.redaction_patterns:
             matches = re.finditer(pattern, page_content)
             for match in matches:
                 redacted.append({
                     'start': match.start(),
                     'end': match.end(),
                     'hiddenText': match.group(0),
                     'revealedText': self._generate_revealed_text(match.group(0)),
                     'revealLevel': RevealLevel.COMPLETE_TRUTH.value
                 })
         return redacted
     
     def _calculate_page_reveal_levels(self, annotations: List[Dict]) -> List[int]:
         """Calculate what reveal levels are present on this page"""
         levels = set()
         for annotation in annotations:
             levels.add(annotation.get('revealLevel', 1))
         return sorted(list(levels))
     
     def _parse_year(self, year_str: str) -> Optional[int]:
         """Parse year from various string formats"""
         if not year_str:
             return None
         # Extract 4-digit year from strings like "April 2, 2024"
         year_match = re.search(r'\b(19|20)\d{2}\b', year_str)
         return int(year_match.group(0)) if year_match else None
     
     def _get_character_arc_stage(self, character: str, year: Optional[int]) -> str:
         """Get character story arc stage"""
         arc_stages = {
             'MB': {
                 'early': 'family_guardian',
                 'middle': 'secret_keeper', 
                 'late': 'final_warnings'
             },
             'JR': {
                 'early': 'initial_research',
                 'middle': 'growing_concern',
                 'late': 'disappearance'
             },
             'EW': {
                 'early': 'structural_analysis',
                 'middle': 'anomaly_discovery',
                 'late': 'safety_concerns'
             },
             'SW': {
                 'current': 'sister_investigation'
             }
         }
         
         stages = arc_stages.get(character, {})
         if not year:
             return 'unknown'
         elif year < 1980:
             return stages.get('early', 'early')
         elif year < 1990:
             return stages.get('middle', 'middle')
         elif year < 2000:
             return stages.get('late', 'late')
         else:
             return stages.get('current', 'current')
     
     def _find_related_annotations(self, annotation: Dict) -> List[str]:
         """Find IDs of related annotations"""
         # Simple keyword matching for now
         keywords = annotation['text'].lower().split()
         related = []
         for other in self.annotations:
             if other['id'] != annotation['id']:
                 other_keywords = other['text'].lower().split()
                 if len(set(keywords) & set(other_keywords)) > 2:
                     related.append(other['id'])
         return related[:3]  # Max 3 related
     
     def _get_character_full_name(self, character: str) -> str:
         """Get full character name"""
         names = {
             'MB': 'Margaret Blackthorn',
             'JR': 'James Reed',
             'EW': 'Eliza Winston',
             'SW': 'Simon Wells',
             'Detective Sharma': 'Detective Moira Sharma',
             'Dr. Chambers': 'Dr. E. Chambers'
         }
         return names.get(character, character)
     
     def _get_character_role(self, character: str) -> str:
         """Get character role description"""
         roles = {
             'MB': 'Family Guardian',
             'JR': 'Independent Researcher',
             'EW': 'Structural Engineer',
             'SW': 'Current Investigator',
             'Detective Sharma': 'Police Investigator',
             'Dr. Chambers': 'Government Analyst'
         }
         return roles.get(character, 'Unknown')
     
     def _generate_story_arc(self, character: str, annotations: List[Dict]) -> Dict:
         """Generate character story arc"""
         return {
             'character': character,
             'totalAnnotations': len(annotations),
             'timeSpan': f"{min(a.get('year', 1967) for a in annotations if a.get('year'))}-{max(a.get('year', 1967) for a in annotations if a.get('year'))}",
             'keyThemes': self._extract_character_themes(annotations),
             'mysterySeverity': self._calculate_mystery_severity(annotations)
         }
     
     def _analyze_mystery_involvement(self, character: str, annotations: List[Dict]) -> Dict:
         """Analyze character's involvement in the mystery"""
         return {
             'involvementLevel': 'high' if len(annotations) > 5 else 'medium' if len(annotations) > 2 else 'low',
             'disappearanceRisk': character in ['JR', 'SW'] and any('disappear' in a['text'].lower() for a in annotations),
             'knowledgeLevel': self._assess_knowledge_level(annotations),
             'lastActivity': max(a.get('year', 1967) for a in annotations if a.get('year'))
         }
     
     def _find_disappearance_clues(self, character: str, annotations: List[Dict]) -> List[str]:
         """Find clues about character disappearances"""
         disappearance_keywords = ['disappear', 'missing', 'vanish', 'gone', 'last entry', 'final']
         clues = []
         for annotation in annotations:
             text_lower = annotation['text'].lower()
             if any(keyword in text_lower for keyword in disappearance_keywords):
                 clues.append(annotation['text'][:100] + '...' if len(annotation['text']) > 100 else annotation['text'])
         return clues
     
     def _extract_character_themes(self, annotations: List[Dict]) -> List[str]:
         """Extract key themes from character's annotations"""
         all_text = ' '.join(a['text'].lower() for a in annotations)
         theme_keywords = {
             'supernatural': ['entity', 'manifestation', 'supernatural', 'otherworld', 'dimension'],
             'architecture': ['building', 'structure', 'foundation', 'room', 'chamber'],
             'investigation': ['research', 'study', 'investigate', 'analyze', 'evidence'],
             'danger': ['danger', 'warning', 'threat', 'disappear', 'missing'],
             'family_secrets': ['family', 'secret', 'tradition', 'ritual', 'guardian']
         }
         
         present_themes = []
         for theme, keywords in theme_keywords.items():
             if any(keyword in all_text for keyword in keywords):
                 present_themes.append(theme)
         return present_themes
     
     def _calculate_mystery_severity(self, annotations: List[Dict]) -> str:
         """Calculate how severe the mystery becomes through this character"""
         severity_keywords = ['dangerous', 'entity', 'disappear', 'warning', 'threat', 'supernatural']
         severity_score = sum(1 for annotation in annotations 
                             for keyword in severity_keywords 
                             if keyword in annotation['text'].lower())
         
         if severity_score >= 5:
             return 'extreme'
         elif severity_score >= 3:
             return 'high'
         elif severity_score >= 1:
             return 'medium'
         else:
             return 'low'
     
     def _assess_knowledge_level(self, annotations: List[Dict]) -> str:
         """Assess character's knowledge level about the mystery"""
         knowledge_keywords = ['know', 'understand', 'explain', 'theory', 'cause', 'reason']
         knowledge_score = sum(1 for annotation in annotations 
                              for keyword in knowledge_keywords 
                              if keyword in annotation['text'].lower())
         
         if knowledge_score >= 3:
             return 'high'
         elif knowledge_score >= 1:
             return 'medium'
         else:
             return 'low'
     
     def _generate_unlock_conditions_system(self) -> Dict:
         """Generate the complete unlock conditions system"""
         return {
             'characterDiscovery': {
                 'MB': 'Find Margaret\'s first annotation',
                 'JR': 'Discover research notes',
                 'EW': 'View engineering analysis',
                 'SW': 'Read modern investigation',
                 'Detective Sharma': 'Access police files',
                 'Dr. Chambers': 'Unlock government documents'
             },
             'progressionGates': {
                 'family_secrets': 'Interact with 3 Margaret annotations',
                 'research_phase': 'Read James Reed\'s methodology',
                 'modern_mystery': 'Discover missing persons connection',
                 'complete_truth': 'Unlock all character timelines'
             }
         }
     
     def _generate_character_progression_system(self) -> Dict:
         """Generate character progression tracking"""
         return {
             'discoveryOrder': ['MB', 'JR', 'EW', 'SW', 'Detective Sharma', 'Dr. Chambers'],
             'storyMilestones': [
                 'First family annotation',
                 'Research methodology discovered',
                 'Engineering anomalies found',
                 'Modern investigation begins',
                 'Police involvement',
                 'Government classification'
             ],
             'unlockRewards': {
                 'character_focus_mode': 'View all annotations by specific character',
                 'timeline_view': 'See chronological story development',
                 'mystery_tracker': 'Track disappearance connections',
                 'complete_revelation': 'Full supernatural truth revealed'
             }
         }
     
     def extract_embedded_annotations(self):
         """Extract embedded annotations from already processed chapters"""
         print("📝 Extracting embedded annotations from processed content...")
         embedded_count = 0
         
         for chapter in self.chapters:
             for page in chapter['pages']:
                 for annotation in page['annotations']:
                     if annotation.get('isEmbedded'):
                         embedded_count += 1
         
         print(f"   📝 Found {embedded_count} embedded annotations")
     
     def process_redacted_content(self):
         """Process redacted content across all chapters"""
         print("🔒 Processing redacted content...")
         
         redacted_count = 0
         for chapter in self.chapters:
             for page in chapter['pages']:
                 redacted_sections = page.get('redactedSections', [])
                 redacted_count += len(redacted_sections)
                 self.redacted_content.extend(redacted_sections)
         
         print(f"   🔒 Found {redacted_count} redacted sections")
     
     def create_web_app_data(self):
         """Create optimized data for web app"""
         print("🌐 Creating web app data...")
         
         # Create web output directory
         self.web_output_dir.mkdir(parents=True, exist_ok=True)
         
         # Create simplified data for web app performance
         web_book_data = {
             'title': 'Blackthorn Manor Archive',
             'chapters': [],
             'characters': self.character_timeline,
             'revealLevels': self.revelation_system['revealLevels']
         }
         
         # Simplify chapters for web
         for chapter in self.chapters[:2]:  # Start with first 2 chapters for web demo
             web_chapter = {
                 'name': chapter['chapterName'],
                 'pages': []
             }
             
             for page in chapter['pages'][:10]:  # Limit pages for demo
                 web_page = {
                     'pageNumber': page['pageNumber'],
                     'content': page['content'],
                     'annotations': page['annotations'][:6],  # Limit annotations for performance
                     'revealLevels': page.get('revealLevels', [1])
                 }
                 web_chapter['pages'].append(web_page)
             
             web_book_data['chapters'].append(web_chapter)
         
         # Save web data
         with open(self.web_output_dir / "web_book_data.json", 'w', encoding='utf-8') as f:
             json.dump(web_book_data, f, indent=2, ensure_ascii=False)
         
         print(f"   🌐 Saved web app data to {self.web_output_dir}")
     
     def _generate_enhanced_character_data(self) -> Dict:
         """Generate enhanced character data with full information"""
         return {
             'characters': {
                 'MB': {
                     'name': 'Margaret Blackthorn',
                     'fullName': 'Margaret Blackthorn',
                     'years': '1930-1999',
                     'description': 'Last surviving member of the Blackthorn family. Maintained the estate and its dangerous secrets until her death. Her elegant blue script reveals family knowledge passed down through generations.',
                     'role': 'Family Guardian',
                     'annotationStyle': {
                         'fontFamily': 'Dancing Script',
                         'fontSize': 10,
                         'color': '#2653a3',
                         'fontStyle': 'italic',
                         'description': 'Elegant blue script with careful, deliberate strokes'
                     },
                     'storyArc': self.character_timeline.get('MB', {}).get('storyArc', {}),
                     'mysteryRole': 'Keeper of family secrets and ancient protective rituals'
                 },
                 'JR': {
                     'name': 'James Reed',
                     'fullName': 'James Reed',
                     'years': '1984-1990',
                     'description': 'Independent researcher who investigated the manor\'s architectural anomalies. His messy black ballpoint notes document his growing unease before his disappearance in 1989.',
                     'role': 'Independent Researcher',
                     'annotationStyle': {
                         'fontFamily': 'Kalam',
                         'fontSize': 9,
                         'color': '#1a1a1a',
                         'fontStyle': 'normal',
                         'description': 'Messy black ballpoint, increasingly hurried'
                     },
                     'storyArc': self.character_timeline.get('JR', {}).get('storyArc', {}),
                     'mysteryRole': 'Academic investigator who uncovered too much truth'
                 },
                 'EW': {
                     'name': 'Eliza Winston',
                     'fullName': 'Eliza Winston',
                     'years': '1995-1999',
                     'description': 'Structural engineer commissioned to assess the building\'s safety. Her precise red pen annotations reveal impossible architectural anomalies before her sudden departure.',
                     'role': 'Structural Engineer',
                     'annotationStyle': {
                         'fontFamily': 'Architects Daughter',
                         'fontSize': 10,
                         'color': '#c41e3a',
                         'fontStyle': 'normal',
                         'description': 'Precise red pen with engineering accuracy'
                     },
                     'storyArc': self.character_timeline.get('EW', {}).get('storyArc', {}),
                     'mysteryRole': 'Technical expert who documented structural impossibilities'
                 },
                 'SW': {
                     'name': 'Simon Wells',
                     'fullName': 'Simon Wells',
                     'years': '2024+',
                     'description': 'Current investigator exploring the manor\'s mysteries. His hurried pencil notes document his desperate search for his missing sister Claire.',
                     'role': 'Current Investigator',
                     'annotationStyle': {
                         'fontFamily': 'Kalam',
                         'fontSize': 9,
                         'color': '#2c2c2c',
                         'fontStyle': 'normal',
                         'description': 'Hurried pencil, emotionally charged'
                     },
                     'storyArc': self.character_timeline.get('SW', {}).get('storyArc', {}),
                     'mysteryRole': 'Modern investigator seeking missing sister'
                 },
                 'Detective Sharma': {
                     'name': 'Detective Sharma',
                     'fullName': 'Detective Moira Sharma',
                     'years': '2024+',
                     'description': 'County Police detective investigating multiple disappearances at Blackthorn Manor. Her official green ink documents growing evidence of connected cases.',
                     'role': 'Police Investigator',
                     'annotationStyle': {
                         'fontFamily': 'Courier Prime',
                         'fontSize': 8,
                         'color': '#006400',
                         'fontStyle': 'normal',
                         'description': 'Official green ink, professional documentation'
                     },
                     'storyArc': self.character_timeline.get('Detective Sharma', {}).get('storyArc', {}),
                     'mysteryRole': 'Law enforcement connecting missing persons cases'
                 },
                 'Dr. Chambers': {
                     'name': 'Dr. Chambers',
                     'fullName': 'Dr. E. Chambers',
                     'years': '2024+',
                     'description': 'Government analyst with Department 8, specializing in anomalous phenomena. Official black ink stamps and classifications indicate high-level interest.',
                     'role': 'Government Analyst',
                     'annotationStyle': {
                         'fontFamily': 'Courier Prime',
                         'fontSize': 8,
                         'color': '#000000',
                         'fontStyle': 'normal',
                         'description': 'Official black ink with government classifications'
                     },
                     'storyArc': self.character_timeline.get('Dr. Chambers', {}).get('storyArc', {}),
                     'mysteryRole': 'Government oversight of anomalous phenomena'
                 }
             },
             'temporalRules': {
                 'pre2000': {
                     'allowedTypes': ['marginalia'],
                     'allowedZones': ['leftMargin', 'rightMargin', 'topMargin', 'bottomMargin'],
                     'description': 'Pre-2000 annotations are fixed historical documents',
                     'characters': ['MB', 'JR', 'EW']
                 },
                 'post2000': {
                     'allowedTypes': ['postIt', 'sticker'],
                     'allowedZones': ['leftMargin', 'rightMargin', 'topMargin', 'bottomMargin', 'content'],
                     'description': 'Post-2000 annotations are interactive and draggable',
                     'characters': ['SW', 'Detective Sharma', 'Dr. Chambers']
                 }
             },
             'progressiveRevelation': self.revelation_system
         }

     def _parse_character(self, character_field) -> str:
        if isinstance(character_field, list):
            return character_field[0] if character_field else "Unknown"
        return character_field or "Unknown"
    
    def _extract_chapter_number(self, file_path: Path) -> int:
        match = re.search(r'CHAPTER_([IVX]+)', file_path.name)
        if match:
            return self._roman_to_int(match.group(1))
        return 999
    
    def _roman_to_int(self, roman: str) -> int:
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
    
    def generate_comprehensive_statistics(self):
        """Generate comprehensive statistics for the enhanced book"""
        print("\n📊 ENHANCED CONTENT STATISTICS")
        
        total_pages = sum(len(chapter['pages']) for chapter in self.chapters)
        total_words = sum(chapter['wordCount'] for chapter in self.chapters)
        total_annotations = len(self.annotations)
        
        print(f"   📚 Total Chapters: {len(self.chapters)}")
        print(f"   📄 Total Pages: {total_pages}")
        print(f"   🔤 Total Words: {total_words:,}")
        print(f"   📝 Total Annotations: {total_annotations}")
        print(f"   📖 Average Words per Page: {total_words // total_pages if total_pages > 0 else 0}")
        
        # Character statistics
        print("\n👥 CHARACTER BREAKDOWN:")
        for character, timeline in self.character_timeline.items():
            count = len(timeline['timeline'])
            role = timeline['role']
            print(f"   {character}: {count} annotations ({role})")
        
        # Reveal level statistics
        print("\n🔓 REVELATION LEVELS:")
        for level in RevealLevel:
            count = len([a for a in self.annotations if a.get('revealLevel') == level.value])
            print(f"   Level {level.value} ({level.name}): {count} items")
        
        # Enhanced features
        print("\n✨ ENHANCED FEATURES:")
        print(f"   🔒 Redacted sections: {len(self.redacted_content)}")
        print(f"   🎭 Character timelines: {len(self.character_timeline)}")
        print(f"   📱 Progressive revelation levels: {len(RevealLevel)}")
        print(f"   🔍 Missing persons mystery: Active")

def main():
    """Enhanced main entry point"""
    try:
        processor = EnhancedContentProcessor()
        processor.run()
    except Exception as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()