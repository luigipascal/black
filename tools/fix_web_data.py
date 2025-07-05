#!/usr/bin/env python3
"""
Fixed Web Book Data Processor for Blackthorn Manor
Properly loads and organizes all content into the web app format
"""

import json
import re
import os
from pathlib import Path
import uuid
from typing import Dict, List, Any, Optional
import math

class FixedWebDataProcessor:
    def __init__(self):
        self.base_path = Path(__file__).parent.parent
        self.annotations = []
        self.chapters = []
        self.front_matter_content = ""
        self.back_matter_content = ""
        self.character_map = {
            'MB': {
                'fullName': 'Margaret Blackthorn',
                'role': 'Family Guardian',
                'style': 'elegant-blue-script',
                'patterns': ['[Elegant blue script]', 'elegant blue script', 'MB,', '-MB']
            },
            'JR': {
                'fullName': 'James Reed',
                'role': 'Independent Researcher', 
                'style': 'messy-black-ballpoint',
                'patterns': ['[Messy black ballpoint]', 'messy black ballpoint', 'JR,', '-JR']
            },
            'EW': {
                'fullName': 'Eliza Winston',
                'role': 'Structural Engineer',
                'style': 'precise-red-pen',
                'patterns': ['[Precise red pen]', 'precise red pen', 'EW,', '-EW']
            },
            'SW': {
                'fullName': 'Simon Wells',
                'role': 'Current Investigator',
                'style': 'hurried-pencil',
                'patterns': ['[Hurried pencil]', 'hurried pencil', 'SW,', '-SW']
            },
            'Detective': {
                'fullName': 'Detective Moira Sharma',
                'role': 'Police Investigator',
                'style': 'official-green',
                'patterns': ['Detective', 'green ink', 'County Police']
            },
            'Chambers': {
                'fullName': 'Dr. E. Chambers',
                'role': 'Government Analyst',
                'style': 'official-black',
                'patterns': ['Chambers', 'official', 'classified', 'Department']
            }
        }
        
    def load_annotations(self):
        """Load the original annotations.json file"""
        annotations_file = self.base_path / 'annotations.json'
        try:
            with open(annotations_file, 'r', encoding='utf-8') as f:
                self.annotations = json.load(f)
            print(f"✅ Loaded {len(self.annotations)} annotations from annotations.json")
        except Exception as e:
            print(f"❌ Error loading annotations: {e}")
            self.annotations = []
    
    def identify_character(self, text: str) -> str:
        """Identify character from annotation text"""
        text_lower = text.lower()
        
        for char_code, char_data in self.character_map.items():
            for pattern in char_data['patterns']:
                if pattern.lower() in text_lower:
                    return char_code
        
        # Check for years to determine era
        if any(year in text for year in ['2024', '2023', '2022']):
            if 'detective' in text_lower or 'police' in text_lower:
                return 'Detective'
            return 'SW'
        elif any(year in text for year in ['199', '198', '197']):
            if 'red pen' in text_lower or 'technical' in text_lower:
                return 'EW'
            elif 'ballpoint' in text_lower or 'university' in text_lower:
                return 'JR'
            else:
                return 'MB'
        elif any(year in text for year in ['196', '197']):
            return 'MB'
            
        return 'Unknown'
    
    def clean_annotation_text(self, text: str) -> str:
        """Remove character indicators from annotation text"""
        # Remove character style indicators
        patterns = [
            r'\[Elegant blue script\]\s*',
            r'\[Messy black ballpoint\]\s*',
            r'\[Precise red pen\]\s*',
            r'\[Hurried pencil\]\s*',
            r'\[Detective.*?\]\s*',
            r'\[.*?green ink.*?\]\s*',
            r'\s*-[A-Z]{1,2},?\s*\d{4}.*?$',
            r'\s*-[A-Z]{1,2}$'
        ]
        
        for pattern in patterns:
            text = re.sub(pattern, '', text, flags=re.IGNORECASE)
        
        return text.strip()
    
    def determine_annotation_type(self, annotation: Dict) -> str:
        """Determine if annotation should be marginalia or postIt"""
        year = annotation.get('year')
        annotation_type = annotation.get('type', 'marginalia')
        
        # Pre-2000 are typically marginalia (fixed)
        if year and year < 2000:
            return 'marginalia'
        # Post-2000 are typically stickers/post-its (draggable)
        elif year and year >= 2000:
            return 'postIt'
        # Default based on original type
        elif annotation_type == 'sticker':
            return 'postIt'
        else:
            return 'marginalia'
    
    def load_chapter_files(self):
        """Load all chapter markdown files"""
        chapter_files = []
        
        # Check root directory
        for i in range(1, 12):
            chapter_file = self.base_path / f'CHAPTER_{self.roman_numeral(i)}_*.md'
            matches = list(self.base_path.glob(f'CHAPTER_{self.roman_numeral(i)}_*.md'))
            if matches:
                chapter_files.extend(matches)
        
        # Check content/chapters directory  
        content_chapters = self.base_path / 'content' / 'chapters'
        if content_chapters.exists():
            chapter_files.extend(content_chapters.glob('CHAPTER_*.md'))
        
        chapter_files = sorted(set(chapter_files))
        
        for chapter_file in chapter_files:
            try:
                with open(chapter_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                    
                chapter_name = chapter_file.stem
                self.chapters.append({
                    'name': chapter_name,
                    'content': content,
                    'file': str(chapter_file)
                })
                print(f"✅ Loaded {chapter_name}")
            except Exception as e:
                print(f"❌ Error loading {chapter_file}: {e}")
        
        print(f"✅ Loaded {len(self.chapters)} chapters")
    
    def roman_numeral(self, num):
        """Convert number to Roman numeral"""
        values = [10, 9, 5, 4, 1]
        symbols = ['X', 'IX', 'V', 'IV', 'I']
        roman_num = ''
        i = 0
        while num > 0:
            for _ in range(num // values[i]):
                roman_num += symbols[i]
                num -= values[i]
            i += 1
        return roman_num
    
    def load_front_matter(self):
        """Load front matter content"""
        front_file = self.base_path / 'front_matter.md'
        try:
            with open(front_file, 'r', encoding='utf-8') as f:
                self.front_matter_content = f.read()
            print(f"✅ Loaded front matter")
        except Exception as e:
            print(f"❌ Error loading front matter: {e}")
            self.front_matter_content = ""
    
    def load_back_matter(self):
        """Load back matter content"""
        back_file = self.base_path / 'back_matter.md'
        try:
            with open(back_file, 'r', encoding='utf-8') as f:
                self.back_matter_content = f.read()
            print(f"✅ Loaded back matter")
        except Exception as e:
            print(f"❌ Error loading back matter: {e}")
            self.back_matter_content = ""
    
    def split_into_pages(self, content: str, target_pages: int) -> List[str]:
        """Split content into specified number of pages"""
        if not content.strip():
            return [content]
            
        # Split by paragraphs
        paragraphs = content.split('\n\n')
        if len(paragraphs) <= target_pages:
            return paragraphs
        
        # Calculate paragraphs per page
        paras_per_page = max(1, len(paragraphs) // target_pages)
        pages = []
        
        for i in range(0, len(paragraphs), paras_per_page):
            page_paras = paragraphs[i:i + paras_per_page]
            pages.append('\n\n'.join(page_paras))
        
        return pages[:target_pages]  # Ensure we don't exceed target
    
    def assign_annotations_to_pages(self, all_pages: List[Dict], annotations: List[Dict]) -> List[Dict]:
        """Distribute annotations across pages"""
        
        # Create annotation index by chapter
        chapter_annotations = {}
        front_annotations = []
        back_annotations = []
        
        for ann in annotations:
            chapter = ann.get('chapter', '')
            if not chapter or chapter == 'null':
                if any(keyword in ann.get('text', '').lower() for keyword in ['finch', 'dedication', 'miss margaret']):
                    front_annotations.append(ann)
                else:
                    back_annotations.append(ann)
            else:
                if chapter not in chapter_annotations:
                    chapter_annotations[chapter] = []
                chapter_annotations[chapter].append(ann)
        
        print(f"📊 Annotation distribution:")
        print(f"   Front matter: {len(front_annotations)}")
        print(f"   Chapters: {sum(len(anns) for anns in chapter_annotations.values())}")
        print(f"   Back matter: {len(back_annotations)}")
        
        # Assign annotations to pages
        for page in all_pages:
            page_annotations = []
            
            if page['section'] == 'front':
                # Distribute front annotations across front pages
                if front_annotations:
                    ann_per_page = max(1, len(front_annotations) // 26)
                    start_idx = (page['actualPageNumber'] - 1) * ann_per_page
                    end_idx = start_idx + ann_per_page
                    page_annotations = front_annotations[start_idx:end_idx]
            
            elif page['section'] == 'chapters':
                # Match annotations by chapter name
                chapter_name = page.get('chapterName', '')
                if chapter_name in chapter_annotations:
                    chapter_anns = chapter_annotations[chapter_name]
                    # Distribute evenly across chapter pages
                    chapter_pages = [p for p in all_pages if p.get('chapterName') == chapter_name]
                    if chapter_pages:
                        anns_per_page = max(1, len(chapter_anns) // len(chapter_pages))
                        page_index = chapter_pages.index(page)
                        start_idx = page_index * anns_per_page
                        end_idx = start_idx + anns_per_page
                        page_annotations = chapter_anns[start_idx:end_idx]
            
            elif page['section'] == 'back':
                # Distribute back annotations across back pages
                if back_annotations:
                    back_pages = [p for p in all_pages if p['section'] == 'back']
                    if back_pages:
                        anns_per_page = max(1, len(back_annotations) // len(back_pages))
                        page_index = back_pages.index(page)
                        start_idx = page_index * anns_per_page
                        end_idx = start_idx + anns_per_page
                        page_annotations = back_annotations[start_idx:end_idx]
            
            # Process annotations for this page
            processed_annotations = []
            for ann in page_annotations:
                character = self.identify_character(ann.get('text', ''))
                cleaned_text = self.clean_annotation_text(ann.get('text', ''))
                
                processed_ann = {
                    'id': ann.get('id', str(uuid.uuid4())),
                    'character': character,
                    'text': cleaned_text,
                    'type': self.determine_annotation_type(ann),
                    'year': ann.get('year'),
                    'revealLevel': self.get_reveal_level(character, ann.get('year')),
                    'characterStyle': self.character_map.get(character, {}).get('style', 'unknown'),
                    'position': self.generate_position(),
                    'isDraggable': self.determine_annotation_type(ann) == 'postIt'
                }
                processed_annotations.append(processed_ann)
            
            page['annotations'] = processed_annotations
            page['annotationCount'] = len(processed_annotations)
        
        return all_pages
    
    def get_reveal_level(self, character: str, year: Optional[int]) -> int:
        """Determine revelation level for annotation"""
        if character == 'Unknown' or not year:
            return 1
        elif character == 'MB':
            return 2
        elif character in ['JR', 'EW']:
            return 3
        elif character in ['SW', 'Detective']:
            return 4
        elif character == 'Chambers':
            return 5
        else:
            return 1
    
    def generate_position(self) -> Dict[str, float]:
        """Generate random but reasonable position for annotation"""
        import random
        
        # Margin positions (left/right margins and reasonable Y positions)
        zones = [
            {'x': 0.02, 'y_range': (0.1, 0.9)},  # Left margin
            {'x': 0.85, 'y_range': (0.1, 0.9)},  # Right margin  
            {'x_range': (0.3, 0.7), 'y': 0.05},  # Top margin
            {'x_range': (0.3, 0.7), 'y': 0.95}   # Bottom margin
        ]
        
        zone = random.choice(zones)
        
        if 'x_range' in zone:
            x = random.uniform(*zone['x_range'])
            y = zone['y']
        else:
            x = zone['x']
            y = random.uniform(*zone['y_range'])
        
        return {
            'x': x,
            'y': y,
            'rotation': random.uniform(-0.1, 0.1)  # Slight rotation
        }
    
    def process_redacted_content(self, content: str) -> tuple:
        """Process content for redacted sections"""
        # Look for content that should be redacted
        redacted_patterns = [
            r'████+',  # Existing redactions
            r'\[REDACTED\]',
            r'\[CLASSIFIED\]',
            r'Department 8',
            r'containment protocol',
        ]
        
        redacted_sections = []
        processed_content = content
        
        for i, pattern in enumerate(redacted_patterns):
            matches = list(re.finditer(pattern, processed_content, re.IGNORECASE))
            for match in matches:
                redacted_sections.append({
                    'id': f'redacted_{i}_{match.start()}',
                    'start': match.start(),
                    'end': match.end(),
                    'revealLevel': 5,
                    'originalText': match.group()
                })
        
        return processed_content, redacted_sections
    
    def process(self):
        """Main processing function"""
        print("🏰 Starting Blackthorn Manor Data Processing...")
        
        # Load all source data
        self.load_annotations()
        self.load_chapter_files()
        self.load_front_matter()
        self.load_back_matter()
        
        # Process front matter (26 pages)
        front_pages_content = self.split_into_pages(self.front_matter_content, 26)
        front_pages = []
        
        for i, content in enumerate(front_pages_content):
            processed_content, redacted_sections = self.process_redacted_content(content)
            front_pages.append({
                'pageNumber': i + 1,
                'actualPageNumber': i + 1,
                'type': 'front_matter',
                'section': 'front',
                'content': processed_content,
                'wordCount': len(processed_content.split()),
                'annotations': [],
                'annotationCount': 0,
                'redactedSections': redacted_sections,
                'revealLevels': [1]
            })
        
        # Process chapters (75 pages total)
        chapter_pages = []
        current_page = 27
        target_chapter_pages = 75
        pages_per_chapter = max(1, target_chapter_pages // len(self.chapters))
        
        for chapter in self.chapters:
            chapter_content_pages = self.split_into_pages(chapter['content'], pages_per_chapter)
            
            for i, content in enumerate(chapter_content_pages):
                processed_content, redacted_sections = self.process_redacted_content(content)
                chapter_pages.append({
                    'pageNumber': current_page,
                    'actualPageNumber': current_page,
                    'type': 'chapter',
                    'section': 'chapters',
                    'chapterName': chapter['name'],
                    'content': processed_content,
                    'wordCount': len(processed_content.split()),
                    'annotations': [],
                    'annotationCount': 0,
                    'redactedSections': redacted_sections,
                    'revealLevels': [1, 2, 3, 4, 5]
                })
                current_page += 1
        
        # Process back matter (remaining pages up to 247)
        remaining_pages = 247 - len(front_pages) - len(chapter_pages)
        back_pages_content = self.split_into_pages(self.back_matter_content, remaining_pages)
        back_pages = []
        
        for i, content in enumerate(back_pages_content):
            processed_content, redacted_sections = self.process_redacted_content(content)
            back_pages.append({
                'pageNumber': current_page,
                'actualPageNumber': current_page,
                'type': 'back_matter',
                'section': 'back',
                'content': processed_content,
                'wordCount': len(processed_content.split()),
                'annotations': [],
                'annotationCount': 0,
                'redactedSections': redacted_sections,
                'revealLevels': [1, 2, 3, 4, 5],
                'hasEmbeddedContent': len(redacted_sections) > 0
            })
            current_page += 1
        
        # Combine all pages
        all_pages = front_pages + chapter_pages + back_pages
        
        # Assign annotations to pages
        all_pages = self.assign_annotations_to_pages(all_pages, self.annotations)
        
        # Create the final data structure
        web_book_data = {
            'title': 'Blackthorn Manor Archive',
            'subtitle': 'Complete Interactive Edition',
            'author': 'Professor Harold Finch',
            'frontMatter': {
                'title': 'The Architectural History of Blackthorn Manor',
                'pages': front_pages
            },
            'chapters': self.create_chapter_structure(chapter_pages),
            'backMatter': {
                'title': 'Appendices and Historical Documentation',
                'pages': back_pages,
                'totalAnnotations': len([ann for page in back_pages for ann in page['annotations']])
            },
            'characters': self.create_character_data(),
            'revealLevels': {
                '1': {
                    'name': 'Academic Study',
                    'description': 'Original Professor Finch architectural study',
                    'visibleContent': ['academic_text'],
                    'hiddenContent': ['all_annotations', 'redacted_sections']
                },
                '2': {
                    'name': 'Family Secrets',
                    'description': 'Margaret Blackthorne family knowledge revealed',
                    'visibleContent': ['academic_text', 'mb_annotations'],
                    'hiddenContent': ['research_annotations', 'modern_annotations', 'redacted_sections']
                },
                '3': {
                    'name': 'Research Investigation',
                    'description': 'James Reed and Eliza Winston findings',
                    'visibleContent': ['academic_text', 'mb_annotations', 'jr_annotations', 'ew_annotations'],
                    'hiddenContent': ['modern_annotations', 'partial_redacted_sections']
                },
                '4': {
                    'name': 'Modern Mystery',
                    'description': 'Current investigation and disappearances',
                    'visibleContent': ['all_annotations'],
                    'hiddenContent': ['classified_redactions']
                },
                '5': {
                    'name': 'Complete Truth',
                    'description': 'Full supernatural revelation',
                    'visibleContent': ['everything'],
                    'hiddenContent': []
                }
            }
        }
        
        # Save the processed data
        output_file = self.base_path / 'web_app' / 'data' / 'web_book_data.json'
        output_file.parent.mkdir(parents=True, exist_ok=True)
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(web_book_data, f, indent=2, ensure_ascii=False)
        
        print(f"\n✅ SUCCESS! Generated complete web book data:")
        print(f"   📄 Total pages: {len(all_pages)}")
        print(f"   📖 Front matter: {len(front_pages)} pages")
        print(f"   📚 Chapters: {len(chapter_pages)} pages")
        print(f"   📋 Back matter: {len(back_pages)} pages")
        print(f"   📝 Total annotations: {sum(page['annotationCount'] for page in all_pages)}")
        print(f"   💾 Saved to: {output_file}")
        
        return web_book_data
    
    def create_chapter_structure(self, chapter_pages: List[Dict]) -> List[Dict]:
        """Organize chapter pages by chapter"""
        chapters_by_name = {}
        
        for page in chapter_pages:
            chapter_name = page.get('chapterName', 'Unknown')
            if chapter_name not in chapters_by_name:
                chapters_by_name[chapter_name] = []
            chapters_by_name[chapter_name].append(page)
        
        chapters = []
        for chapter_name, pages in chapters_by_name.items():
            chapters.append({
                'name': chapter_name,
                'pages': pages
            })
        
        return chapters
    
    def create_character_data(self) -> Dict:
        """Create character metadata"""
        characters = {}
        
        for char_code, char_data in self.character_map.items():
            characters[char_code] = {
                'character': char_code,
                'fullName': char_data['fullName'],
                'role': char_data['role'],
                'timeline': [],
                'storyArc': {
                    'character': char_code,
                    'totalAnnotations': 0,
                    'timeSpan': 'Unknown',
                    'keyThemes': [],
                    'mysterySeverity': 'low'
                },
                'mysteryInvolvement': {
                    'involvementLevel': 'low',
                    'disappearanceRisk': False,
                    'knowledgeLevel': 'low',
                    'lastActivity': 1967
                },
                'disappearanceClues': []
            }
        
        return characters

if __name__ == '__main__':
    processor = FixedWebDataProcessor()
    processor.process()