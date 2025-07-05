# BLACKTHORN MANOR – FLUTTER IMPLEMENTATION GUIDE



## TABLE OF CONTENTS

- [Project Overview](#project-overview)

- [Core Architecture](#core-architecture)

- [Widget Specifications](#widget-specifications)

- [Data Models](#data-models)

- [Visual Design System](#visual-design-system)

- [Implementation Phases](#implementation-phases)

- [Code Examples](#code-examples)





## PROJECT OVERVIEW



### Core Concept

An interactive digital book that simulates a classified government document seized by “Department 8.” Readers purchase access to progressively reveal redacted supernatural content hidden within an academic architectural study, while piecing together the true story through authentic-looking marginalia and supplementary documents.



### Narrative Structure

- **Outer Layer**: Academic study of Victorian manor by Professor Harold Finch

- **Hidden Layer**: Supernatural horror story about interdimensional containment

- **Discovery Method**: Truth revealed through marginalia annotations spanning decades (1960s-2026)

- **Document Types**: Main manuscript + appendix materials (letters, journals, police reports)



### Key Features

- Dual reading modes (single page for mobile, book spread for desktop)

- Temporal annotation system (pre/post-2000)

- Progressive content unlocking via in-app purchases

- Realistic document aging and paper textures

- Interactive post-it notes and marginalia





## CORE ARCHITECTURE



### Page Layout System

```

Fixed Page Structure: 8.5” × 11” (216mm × 279mm)

│ [2.3cm] │ MAIN TEXT │ [2.3cm] │

│ LEFT │ COLUMN │ RIGHT │

│ MARGIN │ (TYPEWRITER) │ MARGIN │

│ ONLY │ │ ONLY │

│ │ Never moves, │ │

│ │ never reflows, │ │

│ │ complete content │ │

```



### Fundamental Layout Laws

1. **Main text width**: Page width minus 4.6cm total (2.3cm left + 2.3cm right)

2. **Main text NEVER shifts, wraps, or reflows** around any annotations

3. **Margins are sacred space** - reserved exclusively for marginalia

4. **Fixed proportions** - no responsive behavior, maintain book authenticity

5. **Content completeness** - main text must be readable as continuous document



### Reading Modes

```dart

Enum ReadingMode {

 singlePage, // Mobile-optimized, one page at a time

 bookSpread, // Desktop/tablet, two pages side by side like real book

}

```



### Document Types

```dart

Enum DocumentType {

 Academic, // Main manuscript with aged paper background

 personalLetter, // Cream/white paper with letterhead

 policeReport, // Official form backgrounds with headers

 journal, // Lined notebook paper texture

 governmentMemo, // Classified document styling with watermarks

 photograph, // Realistic photo paper with aging effects

}

```





## WIDGET SPECIFICATIONS



### Main Document Page Widget

```dart

Class DocumentPage extends StatefulWidget {

 Final int pageNumber;

 Final DocumentPageData pageData;

 Final DocumentType documentType;

 Final Size pageSize;

 Final bool isLeftPage; // For book spread mode



 @override

 \_DocumentPageState createState() => \_DocumentPageState();

}



Class \_DocumentPageState extends State {

 @override

 Widget build(BuildContext context) {

 Return Container(

 Width: widget.pageSize.width,

 Height: widget.pageSize.height,

 Child: Stack(

 Children: [

 // Layer 1: Dynamic background based on document type

 \_buildDocumentBackground(),

 

 // Layer 2: Main content (text or document image)

 \_buildMainContent(),

 

 // Layer 3: Fixed marginalia (pre-2000 only)

 ...widget.pageData.marginalia

 .where((note) => note.date.year <= 1999)

 .map((note) => \_buildFixedMarginalia(note)),

 

 // Layer 4: Draggable post-its (post-2000 only)

 ...widget.pageData.postIts

 .where((note) => note.date.year >= 2000)

 .map((note) => \_buildDraggablePostIt(note)),

 

 // Layer 5: Redacted text overlays (academic documents only)

 If (widget.documentType == DocumentType.academic)

 ...widget.pageData.redactions.map((redaction) =>

 RedactableTextWidget(redaction)

 ),

 

 // Layer 6: Government stamps/markings

 ...widget.pageData.stamps.map((stamp) =>

 GovernmentStamp(stamp)

 ),



 // Layer 7: Page number and book effects

 \_buildPageNumber(),

 \_buildBookEffects(),

 ],

 ),

 );

 }



 Widget \_buildDocumentBackground() {

 Switch (widget.documentType) {

 Case DocumentType.academic:

 Return Container(

 Decoration: BoxDecoration(

 Gradient: LinearGradient(

 Colors: [Color(0xFFF4E8D0), Color(0xFFE8DCC0)],

 Begin: Alignment.topLeft,

 End: Alignment.bottomRight,

 ),

 ),

 Child: Container(

 Decoration: BoxDecoration(

 Image: DecorationImage(

 Image: AssetImage(‘assets/textures/paper\_grain.png’),

 Fit: BoxFit.cover,

 Opacity: 0.3,

 ),

 ),

 ),

 );

 Case DocumentType.personalLetter:

 Return Container(color: Color(0xFFFFFFF0)); // Ivory

 Case DocumentType.policeReport:

 Return Container(color: Color(0xFFF8F8FF)); // Ghost white

 Case DocumentType.journal:

 Return Container(

 Decoration: BoxDecoration(

 Color: Color(0xFFFFFFF0),

 Image: DecorationImage(

 Image: AssetImage(‘assets/textures/lined\_paper.png’),

 Fit: BoxFit.cover,

 ),

 ),

 );

 Case DocumentType.governmentMemo:

 Return Container(

 Color: Color(0xFFF5F5DC),

 Child: Opacity(

 Opacity: 0.1,

 Child: Image.asset(‘assets/textures/classified\_watermark.png’),

 ),

 );

 Default:

 Return Container(color: Colors.white);

 }

 }



 Widget \_buildPageNumber() {

 Return Positioned(

 Bottom: 20,

 Left: widget.isLeftPage ? 20 : null,

 Right: widget.isLeftPage ? null : 20,

 Child: Text(

 ‘${widget.pageData.pageNumber}’,

 Style: TextStyle(

 fontFamily: ‘Courier Prime’,

 fontSize: 10,

 color: Colors.black54,

 ),

 ),

 );

 }



 Widget \_buildBookEffects() {

 If (widget.isLeftPage == null) return Container(); // Single page mode

 

 Return Container(

 Decoration: BoxDecoration(

 Gradient: LinearGradient(

 Begin: widget.isLeftPage! ? Alignment.centerLeft : Alignment.centerRight,

 End: widget.isLeftPage! ? Alignment.centerRight : Alignment.centerLeft,

 Colors: [

 Colors.black.withOpacity(0.1), // Shadow near spine

 Colors.transparent,

 ],

 Stops: [0.0, 0.15],

 ),

 ),

 );

 }

}

```



### Fixed Marginalia Widget (Pre-2000 Annotations)

```dart

Class FixedMarginaliaWidget extends StatelessWidget {

 Final MarginaliaNote note;

 Final EdgeInsets pageMargins;



 Const FixedMarginaliaWidget({

 Key? Key,

 Required this.note,

 Required this.pageMargins,

 }) : super(key: key);



 @override

 Widget build(BuildContext context) {

 Return Positioned(

 Left: \_ensureWithinMargin(note.position.dx),

 Top: note.position.dy,

 Child: GestureDetector(

 onTap: () => \_showEnlargedView(context),

 onLongPress: () => \_showAuthorContext(context),

 child: Container(

 constraints: BoxConstraints(

 maxWidth: pageMargins.left – 10, // Keep within margin

 ),

 Child: Text(

 Note.text,

 Style: \_getStyleForAuthor(note.author),

 Overflow: TextOverflow.visible,

 ),

 ),

 ),

 );

 }



 Double \_ensureWithinMargin(double x) {

 Const marginWidth = 2.3 * 96 / 2.54; // Convert cm to pixels

 Return math.max(0, math.min(x, marginWidth – 10));

 }



 TextStyle \_getStyleForAuthor(String author) {

 Switch (author) {

 Case ‘MB’: // Margaret Blackthorn

 Return TextStyle(

 fontFamily: ‘Dancing Script’,

 color: Color(0xFF2653a3), // Elegant blue

 fontSize: 10,

 fontStyle: FontStyle.italic,

 );

 Case ‘JR’: // James Reed

 Return TextStyle(

 fontFamily: ‘Kalam’,

 color: Color(0xFF1a1a1a), // Black ballpoint

 fontSize: 9,

 fontWeight: FontWeight.w400,

 );

 Case ‘EW’: // Eliza Winston

 Return TextStyle(

 fontFamily: ‘Architects Daughter’,

 color: Color(0xFFc41e3a), // Red pen

 fontSize: 10,

 fontWeight: FontWeight.w500,

 );

 Default:

 Return TextStyle(

 fontFamily: ‘Courier Prime’,

 fontSize: 10,

 color: Colors.black87,

 );

 }

 }



 Void \_showEnlargedView(BuildContext context) {

 showDialog(

 context: context,

 builder: (context) => AlertDialog(

 title: Text(‘${note.author} - ${\_formatDate(note.date)}’),

 content: Text(note.text, style: \_getStyleForAuthor(note.author)),

 actions: [

 TextButton(

 onPressed: () => Navigator.pop(context),

 child: Text(‘Close’),

 ),

 ],

 ),

 );

 }



 Void \_showAuthorContext(BuildContext context) {

 Final authorInfo = \_getAuthorInfo(note.author);

 showDialog(

 context: context,

 builder: (context) => AlertDialog(

 title: Text(authorInfo[‘name’]!),

 content: Column(

 mainAxisSize: MainAxisSize.min,

 crossAxisAlignment: CrossAxisAlignment.start,

 children: [

 Text(authorInfo[‘description’]!),

 SizedBox(height: 10),

 Text(‘Note: ${note.text}’, style: TextStyle(fontStyle: FontStyle.italic)),

 ],

 ),

 Actions: [

 TextButton(

 onPressed: () => Navigator.pop(context),

 child: Text(‘Close’),

 ),

 ],

 ),

 );

 }



 Map \_getAuthorInfo(String author) {

 Switch (author) {

 Case ‘MB’:

 Return {

 ‘name’: ‘Margaret Blackthorn’,

 ‘description’: ‘Last surviving member of the Blackthorn family (1960-1999). Maintained the estate and its secrets until her death.’,

 };

 Case ‘JR’:

 Return {

 ‘name’: ‘James Reed’,

 ‘description’: ‘Independent researcher (1984-1990). Investigated the manor\’s architectural anomalies. Disappeared in 1989.’,

 };

 Case ‘EW’:

 Return {

 ‘name’: ‘Eliza Winston’,

 ‘description’: ‘Structural engineer (1995-1999). Commissioned to assess the building\’s safety. Her reports raised serious concerns.’,

 };

 Default:

 Return {

 ‘name’: ‘Unknown Researcher’,

 ‘description’: ‘Identity and background unknown.’,

 };

 }

 }



 String \_formatDate(DateTime date) {

 Return ‘${date.day}/${date.month}/${date.year}’;

 }

}

```



### Draggable Post-it Widget (Post-2000 Annotations)

```dart

Class DraggablePostItWidget extends StatefulWidget {

 Final PostItAnnotation annotation;

 Final Function(String id, Offset position) onPositionChanged;



 Const DraggablePostItWidget({

 Key? Key,

 Required this.annotation,

 Required this.onPositionChanged,

 }) : super(key: key);



 @override

 \_DraggablePostItWidgetState createState() => \_DraggablePostItWidgetState();

}



Class \_DraggablePostItWidgetState extends State {

 Late Offset \_position;

 Int \_zIndex = 1;



 @override

 Void initState() {

 Super.initState();

 \_position = widget.annotation.currentPosition;

 }



 @override

 Widget build(BuildContext context) {

 Return Positioned(

 Left: \_position.dx,

 Top: \_position.dy,

 Child: Draggable(

 Feedback: Material(

 Color: Colors.transparent,

 Child: \_buildPostItContent(isDragging: true),

 ),

 childWhenDragging: Opacity(

 opacity: 0.3,

 child: \_buildPostItContent(),

 ),

 onDragEnd: (details) {

 setState(() {

 \_position = details.offset;

 });

 Widget.onPositionChanged(widget.annotation.id, details.offset);

 },

 Child: GestureDetector(

 onTap: () => \_bringToFront(),

 onDoubleTap: () => \_rotateSlightly(),

 onLongPress: () => \_showContextMenu(),

 child: \_buildPostItContent(),

 ),

 ),

 );

 }



 Widget \_buildPostItContent({bool isDragging = false}) {

 Return Container(

 Padding: EdgeInsets.all(8),

 Constraints: BoxConstraints(

 maxWidth: \_getMaxWidth(),

 minWidth: 80,

 ),

 Decoration: BoxDecoration(

 Color: \_getPostItColor().withOpacity(isDragging ? 0.8 : 0.9),

 boxShadow: [

 BoxShadow(

 Color: Colors.black.withOpacity(isDragging ? 0.3 : 0.2),

 blurRadius: isDragging ? 6 : 4,

 offset: Offset(2, 2),

 ),

 ],

 borderRadius: BorderRadius.circular(2),

 ),

 Transform: Matrix4.rotationZ(widget.annotation.rotation),

 Child: \_buildPostItText(),

 );

 }



 Widget \_buildPostItText() {

 If (widget.annotation.hasOfficialHeader) {

 Return Column(

 crossAxisAlignment: CrossAxisAlignment.start,

 mainAxisSize: MainAxisSize.min,

 children: [

 Text(

 Widget.annotation.officialHeader ?? ‘’,

 Style: TextStyle(

 fontSize: 8,

 fontWeight: FontWeight.bold,

 color: Colors.black54,

 ),

 ),

 SizedBox(height: 4),

 Text(

 Widget.annotation.text,

 Style: \_getPostItTextStyle(),

 ),

 ],

 );

 }



 Return Text(

 Widget.annotation.text,

 Style: \_getPostItTextStyle(),

 );

 }



 Color \_getPostItColor() {

 Switch (widget.annotation.author) {

 Case ‘SW’: // Simon Wells

 Return Color(0xFFFFFF99); // Yellow

 Case ‘Detective Sharma’:

 Return Color(0xFFFFFFFF); // White

 Case ‘Dr. E. Chambers’:

 Return Color(0xFFF5F5DC); // Beige/manila

 Default:

 Return Color(0xFFFFFF99); // Default yellow

 }

 }



 TextStyle \_getPostItTextStyle() {

 Switch (widget.annotation.author) {

 Case ‘SW’:

 Return TextStyle(

 fontFamily: ‘Kalam’,

 fontSize: 9,

 color: Colors.black87,

 );

 Case ‘Detective Sharma’:

 Return TextStyle(

 fontFamily: ‘Courier Prime’,

 fontSize: 8,

 color: Color(0xFF006400), // Dark green

 fontWeight: FontWeight.w500,

 );

 Case ‘Dr. E. Chambers’:

 Return TextStyle(

 fontFamily: ‘Courier Prime’,

 fontSize: 8,

 color: Colors.black87,

 fontWeight: FontWeight.w400,

 );

 Default:

 Return TextStyle(

 fontFamily: ‘Courier Prime’,

 fontSize: 9,

 color: Colors.black87,

 );

 }

 }



 Double \_getMaxWidth() {

 Switch (widget.annotation.size) {

 Case PostItSize.small:

 Return 120;

 Case PostItSize.medium:

 Return 180;

 Case PostItSize.large:

 Return 250;

 Default:

 Return 150;

 }

 }



 Void \_bringToFront() {

 setState(() {

 \_zIndex = DateTime.now().millisecondsSinceEpoch; // Simple z-index system

 });

 }



 Void \_rotateSlightly() {

 // Add slight rotation animation for realism

 setState(() {

 // Rotate by small random amount

 });

 }



 Void \_showContextMenu() {

 showModalBottomSheet(

 context: context,

 builder: (context) => Container(

 padding: EdgeInsets.all(16),

 child: Column(

 mainAxisSize: MainAxisSize.min,

 children: [

 ListTile(

 Leading: Icon(Icons.edit),

 Title: Text(‘Edit Note’),

 onTap: () {

 Navigator.pop(context);

 \_editNote();

 },

 ),

 ListTile(

 Leading: Icon(Icons.copy),

 Title: Text(‘Duplicate’),

 onTap: () {

 Navigator.pop(context);

 \_duplicateNote();

 },

 ),

 ListTile(

 Leading: Icon(Icons.delete),

 Title: Text(‘Remove’),

 onTap: () {

 Navigator.pop(context);

 \_removeNote();

 },

 ),

 ],

 ),

 ),

 );

 }



 Void \_editNote() {

 // Implementation for editing note

 }



 Void \_duplicateNote() {

 // Implementation for duplicating note

 }



 Void \_removeNote() {

 // Implementation for removing note

 }

}

```



### Redactable Text Widget

```dart

Class RedactableTextWidget extends StatefulWidget {

 Final RedactionData redaction;



 Const RedactableTextWidget({Key? Key, required this.redaction}) : super(key: key);



 @override

 \_RedactableTextWidgetState createState() => \_RedactableTextWidgetState();

}



Class \_RedactableTextWidgetState extends State

 With SingleTickerProviderStateMixin {

 Late AnimationController \_animationController;

 Late Animation \_fadeAnimation;



 Bool get \_isUnlocked => 

 Context.watch().isUnlocked(widget.redaction.unlockKey);



 @override

 Void initState() {

 Super.initState();

 \_animationController = AnimationController(

 Duration: Duration(milliseconds: 1000),

 Vsync: this,

 );

 \_fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(

 CurvedAnimation(parent: \_animationController, curve: Curves.easeInOut),

 );

 }



 @override

 Void dispose() {

 \_animationController.dispose();

 Super.dispose();

 }



 @override

 Widget build(BuildContext context) {

 Return Positioned(

 Left: widget.redaction.position.dx,

 Top: widget.redaction.position.dy,

 Child: GestureDetector(

 onTap: \_isUnlocked ? null : () => \_showUnlockDialog(),

 child: AnimatedSwitcher(

 duration: Duration(milliseconds: 500),

 child: \_isUnlocked 

 ? \_buildRevealedText()

 : \_buildRedactedBars(),

 ),

 ),

 );

 }



 Widget \_buildRedactedBars() {

 Return Container(

 Key: ValueKey(‘redacted’),

 Width: widget.redaction.width,

 Height: widget.redaction.height,

 Decoration: BoxDecoration(

 Color: Colors.black,

 borderRadius: BorderRadius.circular(1),

 ),

 Child: Center(

 Child: Text(

 ‘█’ * widget.redaction.barCount,

 Style: TextStyle(

 Color: Colors.black,

 fontSize: 12,

 fontFamily: ‘Courier Prime’,

 ),

 ),

 ),

 );

 }



 Widget \_buildRevealedText() {

 Return AnimatedBuilder(

 Animation: \_fadeAnimation,

 Builder: (context, child) {

 Return Opacity(

 Opacity: \_fadeAnimation.value,

 Child: Container(

 Key: ValueKey(‘revealed’),

 Width: widget.redaction.width,

 Padding: EdgeInsets.symmetric(horizontal: 2),

 Child: Text(

 Widget.redaction.secretText,

 Style: TextStyle(

 fontFamily: ‘Courier Prime’,

 fontSize: 12,

 color: Color(0xFF2a2a2a),

 backgroundColor: Color(0xFFFFFF99).withOpacity(0.3), // Slight highlight

 ),

 ),

 ),

 );

 },

 );

 }



 Void \_showUnlockDialog() {

 showDialog(

 context: context,

 builder: (context) => AlertDialog(

 title: Text(‘Classified Content’),

 content: Column(

 mainAxisSize: MainAxisSize.min,

 children: [

 Icon(Icons.lock, size: 48, color: Colors.red),

 SizedBox(height: 16),

 Text(‘This content requires ${\_getAccessLevelName()} clearance.’),

 SizedBox(height: 8),

 Text(‘Unlock for ${\_getPrice()}?’),

 ],

 ),

 Actions: [

 TextButton(

 onPressed: () => Navigator.pop(context),

 child: Text(‘Cancel’),

 ),

 ElevatedButton(

 onPressed: () {

 Navigator.pop(context);

 \_purchaseUnlock();

 },

 Child: Text(‘Unlock’),

 ),

 ],

 ),

 );

 }



 String \_getAccessLevelName() {

 Switch (widget.redaction.requiredLevel) {

 Case AccessLevel.classified:

 Return ‘Classified’;

 Case AccessLevel.restricted:

 Return ‘Restricted’;

 Case AccessLevel.topSecret:

 Return ‘Top Secret’;

 Default:

 Return ‘Public’;

 }

 }



 String \_getPrice() {

 Switch (widget.redaction.requiredLevel) {

 Case AccessLevel.classified:

 Return ‘£1.99’;

 Case AccessLevel.restricted:

 Return ‘£2.99’;

 Case AccessLevel.topSecret:

 Return ‘£4.99’;

 Default:

 Return ‘Free’;

 }

 }



 Void \_purchaseUnlock() async {

 // Show loading indicator

 showDialog(

 context: context,

 barrierDismissible: false,

 builder: (context) => Center(child: CircularProgressIndicator()),

 );



 Try {

 // Simulate payment processing

 Await Future.delayed(Duration(seconds: 2));

 

 // Unlock the content

 Context.read().unlockRedaction(widget.redaction.unlockKey);

 

 // Start reveal animation

 \_animationController.forward();

 

 Navigator.pop(context); // Close loading dialog

 

 // Show success message

 ScaffoldMessenger.of(context).showSnackBar(

 SnackBar(

 Content: Text(‘Content unlocked successfully!’),

 backgroundColor: Colors.green,

 ),

 );

 } catch (e) {

 Navigator.pop(context); // Close loading dialog

 

 // Show error message

 ScaffoldMessenger.of(context).showSnackBar(

 SnackBar(

 Content: Text(‘Purchase failed. Please try again.’),

 backgroundColor: Colors.red,

 ),

 );

 }

 }

}

```





## DATA MODELS



### Core Data Models

```dart

Class DocumentPageData {

 Final int pageNumber;

 Final DocumentType documentType;

 Final String? mainText; // For academic documents

 Final String? documentImagePath; // For supplementary documents

 Final List marginalia; // Pre-2000 only

 Final List postIts; // Post-2000 only

 Final List redactions; // Academic documents only

 Final List stamps;



 DocumentPageData({

 Required this.pageNumber,

 Required this.documentType,

 This.mainText,

 This.documentImagePath,

 This.marginalia = const [],

 This.postIts = const [],

 This.redactions = const [],

 This.stamps = const [],

 });



 Factory DocumentPageData.fromJson(Map json) {

 Return DocumentPageData(

 pageNumber: json[‘pageNumber’],

 documentType: DocumentType.values[json[‘documentType’]],

 mainText: json[‘mainText’],

 documentImagePath: json[‘documentImagePath’],

 marginalia: (json[‘marginalia’] as List?)

 ?.map((item) => MarginaliaNote.fromJson(item))

 .toList() ?? [],

 postIts: (json[‘postIts’] as List?)

 ?.map((item) => PostItAnnotation.fromJson(item))

 .toList() ?? [],

 Redactions: (json[‘redactions’] as List?)

 ?.map((item) => RedactionData.fromJson(item))

 .toList() ?? [],

 Stamps: (json[‘stamps’] as List?)

 ?.map((item) => StampData.fromJson(item))

 .toList() ?? [],

 );

 }



 Map toJson() {

 Return {

 ‘pageNumber’: pageNumber,

 ‘documentType’: documentType.index,

 ‘mainText’: mainText,

 ‘documentImagePath’: documentImagePath,

 ‘marginalia’: marginalia.map((item) => item.toJson()).toList(),

 ‘postIts’: postIts.map((item) => item.toJson()).toList(),

 ‘redactions’: redactions.map((item) => item.toJson()).toList(),

 ‘stamps’: stamps.map((item) => item.toJson()).toList(),

 };

 }

}



Class MarginaliaNote {

 Final String id;

 Final String author;

 Final DateTime date; // Must be ≤ 1999

 Final String text;

 Final Offset position; // Must be within margins

 Final String fontStyle;

 Final Color color;



 MarginaliaNote({

 Required this.id,

 Required this.author,

 Required this.date,

 Required this.text,

 Required this.position,

 Required this.fontStyle,

 Required this.color,

 }) : assert(date.year <= 1999, ‘Marginalia notes must be from 1999 or earlier’);



 Factory MarginaliaNote.fromJson(Map json) {

 Return MarginaliaNote(

 Id: json[‘id’],

 Author: json[‘author’],

 Date: DateTime.parse(json[‘date’]),

 Text: json[‘text’],

 Position: Offset(json[‘position’][‘dx’], json[‘position’][‘dy’]),

 fontStyle: json[‘fontStyle’],

 color: Color(json[‘color’]),

 );

 }



 Map toJson() {

 Return {

 ‘id’: id,

 ‘author’: author,

 ‘date’: date.toIso8601String(),

 ‘text’: text,

 ‘position’: {‘dx’: position.dx, ‘dy’: position.dy},

 ‘fontStyle’: fontStyle,

 ‘color’: color.value,

 };

 }

}



Class PostItAnnotation {

 Final String id;

 Final String author;

 Final DateTime date; // Must be ≥ 2000

 Final String text;

 Final Offset currentPosition; // Can be anywhere

 Final Color backgroundColor;

 Final double rotation; // Slight random rotation

 Final PostItSize size;

 Final bool hasOfficialHeader;

 Final String? officialHeader;



 PostItAnnotation({

 Required this.id,

 Required this.author,

 Required this.date,

 Required this.text,

 Required this.currentPosition,

 Required this.backgroundColor,

 This.rotation = 0.0,

 This.size = PostItSize.medium,

 This.hasOfficialHeader = false,

 This.officialHeader,

 }) : assert(date.year >= 2000, ‘Post-it notes must be from 2000 or later’);



 Factory PostItAnnotation.fromJson(Map json) {

 Return PostItAnnotation(

 Id: json[‘id’],

 Author: json[‘author’],

 Date: DateTime.parse(json[‘date’]),

 Text: json[‘text’],

 currentPosition: Offset(json[‘currentPosition’][‘dx’], json[‘currentPosition’][‘dy’]),

 backgroundColor: Color(json[‘backgroundColor’]),

 rotation: json[‘rotation’]?.toDouble() ?? 0.0,

 size: PostItSize.values[json[‘size’] ?? 1],

 hasOfficialHeader: json[‘hasOfficialHeader’] ?? false,

 officialHeader: json[‘officialHeader’],

 );

 }



 Map toJson() {

 Return {

 ‘id’: id,

 ‘author’: author,

 ‘date’: date.toIso8601String(),

 ‘text’: text,

 ‘currentPosition’: {‘dx’: currentPosition.dx, ‘dy’: currentPosition.dy},

 ‘backgroundColor’: backgroundColor.value,

 ‘rotation’: rotation,

 ‘size’: size.index,

 ‘hasOfficialHeader’: hasOfficialHeader,

 ‘officialHeader’: officialHeader,

 };

 }



 PostItAnnotation copyWith({

 String? Id,

 String? Author,

 DateTime? Date,

 String? Text,

 Offset? currentPosition,

 Color? backgroundColor,

 Double? Rotation,

 PostItSize? Size,

 Bool? hasOfficialHeader,

 String? officialHeader,

 }) {

 Return PostItAnnotation(

 Id: id ?? this.id,

 Author: author ?? this.author,

 Date: date ?? this.date,

 Text: text ?? this.text,

 currentPosition: currentPosition ?? this.currentPosition,

 backgroundColor: backgroundColor ?? this.backgroundColor,

 rotation: rotation ?? this.rotation,

 size: size ?? this.size,

 hasOfficialHeader: hasOfficialHeader ?? this.hasOfficialHeader,

 officialHeader: officialHeader ?? this.officialHeader,

 );

 }

}



Class RedactionData {

 Final String id;

 Final Offset position;

 Final double width;

 Final double height;

 Final int barCount;

 Final String unlockKey;

 Final String secretText;

 Final AccessLevel requiredLevel;



 RedactionData({

 Required this.id,

 Required this.position,

 Required this.width,

```dart

 Required this.height,

 Required this.barCount,

 Required this.unlockKey,

 Required this.secretText,

 Required this.requiredLevel,

 });



 Factory RedactionData.fromJson(Map json) {

 Return RedactionData(

 Id: json[‘id’],

 Position: Offset(json[‘position’][‘dx’], json[‘position’][‘dy’]),

 Width: json[‘width’].toDouble(),

 Height: json[‘height’].toDouble(),

 barCount: json[‘barCount’],

 unlockKey: json[‘unlockKey’],

 secretText: json[‘secretText’],

 requiredLevel: AccessLevel.values[json[‘requiredLevel’]],

 );

 }



 Map toJson() {

 Return {

 ‘id’: id,

 ‘position’: {‘dx’: position.dx, ‘dy’: position.dy},

 ‘width’: width,

 ‘height’: height,

 ‘barCount’: barCount,

 ‘unlockKey’: unlockKey,

 ‘secretText’: secretText,

 ‘requiredLevel’: requiredLevel.index,

 };

 }

}



Class StampData {

 Final String id;

 Final String text;

 Final Offset position;

 Final double rotation;

 Final Color color;

 Final StampType type;



 StampData({

 Required this.id,

 Required this.text,

 Required this.position,

 This.rotation = 0.0,

 This.color = Colors.red,

 This.type = StampType.classification,

 });



 Factory StampData.fromJson(Map json) {

 Return StampData(

 Id: json[‘id’],

 Text: json[‘text’],

 Position: Offset(json[‘position’][‘dx’], json[‘position’][‘dy’]),

 Rotation: json[‘rotation’]?.toDouble() ?? 0.0,

 Color: Color(json[‘color’]),

 Type: StampType.values[json[‘type’]],

 );

 }



 Map toJson() {

 Return {

 ‘id’: id,

 ‘text’: text,

 ‘position’: {‘dx’: position.dx, ‘dy’: position.dy},

 ‘rotation’: rotation,

 ‘color’: color.value,

 ‘type’: type.index,

 };

 }

}



Enum PostItSize {

 Small,

 Medium,

 Large,

}



Enum AccessLevel {

 Public, // £0 – visible by default

 Classified, // £1-3 per revelation

 Restricted, // £2-5 per revelation

 topSecret, // £3-7 per revelation

}



Enum StampType {

 Classification,

 Date,

 Signature,

 Department,

}

```



### State Management Models

```dart

Class DocumentState extends ChangeNotifier {

 Map \_postItPositions = {};

 Set \_unlockedRedactions = {};

 Int \_currentPage = 0;

 Double \_zoomLevel = 1.0;

 Offset \_panOffset = Offset.zero;

 AccessLevel \_userAccessLevel = AccessLevel.public;

 ReadingMode \_readingMode = ReadingMode.singlePage;



 // Getters

 Map get postItPositions => Map.unmodifiable(\_postItPositions);

 Set get unlockedRedactions => Set.unmodifiable(\_unlockedRedactions);

 Int get currentPage => \_currentPage;

 Double get zoomLevel => \_zoomLevel;

 Offset get panOffset => \_panOffset;

 AccessLevel get userAccessLevel => \_userAccessLevel;

 ReadingMode get readingMode => \_readingMode;



 // Post-it position management

 Void updatePostItPosition(String id, Offset position) {

 \_postItPositions[id] = position;

 \_saveToPreferences();

 notifyListeners();

 }



 // Redaction unlocking

 Void unlockRedaction(String id) {

 \_unlockedRedactions.add(id);

 \_saveToPreferences();

 notifyListeners();

 }



 Bool isRedactionUnlocked(String id) {

 Return \_unlockedRedactions.contains(id);

 }



 // Page navigation

 Void setCurrentPage(int page) {

 \_currentPage = page;

 notifyListeners();

 }



 // Zoom and pan

 Void setZoomLevel(double zoom) {

 \_zoomLevel = zoom;

 notifyListeners();

 }



 Void setPanOffset(Offset offset) {

 \_panOffset = offset;

 notifyListeners();

 }



 // Access level management

 Void upgradeAccessLevel(AccessLevel newLevel) {

 \_userAccessLevel = newLevel;

 \_saveToPreferences();

 notifyListeners();

 }



 // Reading mode

 Void setReadingMode(ReadingMode mode) {

 \_readingMode = mode;

 \_saveToPreferences();

 notifyListeners();

 }



 // Persistence

 Void \_saveToPreferences() async {

 Final prefs = await SharedPreferences.getInstance();

 

 // Save post-it positions

 Final positionsJson = \_postItPositions.map(

 (key, value) => MapEntry(key, {‘dx’: value.dx, ‘dy’: value.dy}),

 );

 Await prefs.setString(‘postit\_positions’, jsonEncode(positionsJson));

 

 // Save unlocked redactions

 Await prefs.setStringList(‘unlocked\_redactions’, \_unlockedRedactions.toList());

 

 // Save user access level

 Await prefs.setInt(‘access\_level’, \_userAccessLevel.index);

 

 // Save reading mode

 Await prefs.setInt(‘reading\_mode’, \_readingMode.index);

 }



 Void loadFromPreferences() async {

 Final prefs = await SharedPreferences.getInstance();

 

 // Load post-it positions

 Final positionsString = prefs.getString(‘postit\_positions’);

 If (positionsString != null) {

 Final positionsJson = jsonDecode(positionsString) as Map;

 \_postItPositions = positionsJson.map(

 (key, value) => MapEntry(key, Offset(value[‘dx’], value[‘dy’])),

 );

 }

 

 // Load unlocked redactions

 Final unlockedList = prefs.getStringList(‘unlocked\_redactions’);

 If (unlockedList != null) {

 \_unlockedRedactions = unlockedList.toSet();

 }

 

 // Load access level

 Final accessLevelIndex = prefs.getInt(‘access\_level’);

 If (accessLevelIndex != null) {

 \_userAccessLevel = AccessLevel.values[accessLevelIndex];

 }

 

 // Load reading mode

 Final readingModeIndex = prefs.getInt(‘reading\_mode’);

 If (readingModeIndex != null) {

 \_readingMode = ReadingMode.values[readingModeIndex];

 }

 

 notifyListeners();

 }

}



Class AccessProvider extends ChangeNotifier {

 Set \_unlockedContent = {};

 AccessLevel \_currentLevel = AccessLevel.public;



 Set get unlockedContent => Set.unmodifiable(\_unlockedContent);

 AccessLevel get currentLevel => \_currentLevel;



 Bool isUnlocked(String key) {

 Return \_unlockedContent.contains(key);

 }



 Future purchaseAccess(String key, AccessLevel requiredLevel) async {

 Try {

 // Implement actual payment processing here

 Final success = await \_processPayment(key, requiredLevel);

 

 If (success) {

 \_unlockedContent.add(key);

 If (requiredLevel.index > \_currentLevel.index) {

 \_currentLevel = requiredLevel;

 }

 Await \_saveToPreferences();

 notifyListeners();

 return true;

 }

 Return false;

 } catch (e) {

 Print(‘Payment failed: $e’);

 Return false;

 }

 }



 Future \_processPayment(String key, AccessLevel level) async {

 // Simulate payment processing

 Await Future.delayed(Duration(seconds: 2));

 Return true; // In real implementation, handle actual payment

 }



 Future \_saveToPreferences() async {

 Final prefs = await SharedPreferences.getInstance();

 Await prefs.setStringList(‘unlocked\_content’, \_unlockedContent.toList());

 Await prefs.setInt(‘current\_access\_level’, \_currentLevel.index);

 }



 Future loadFromPreferences() async {

 Final prefs = await SharedPreferences.getInstance();

 Final unlockedList = prefs.getStringList(‘unlocked\_content’);

 If (unlockedList != null) {

 \_unlockedContent = unlockedList.toSet();

 }

 Final levelIndex = prefs.getInt(‘current\_access\_level’);

 If (levelIndex != null) {

 \_currentLevel = AccessLevel.values[levelIndex];

 }

 notifyListeners();

 }

}

```





## VISUAL DESIGN SYSTEM



### Typography

```dart

Class AppTypography {

 Static const String primaryFont = ‘Courier Prime’;

 Static const String handwritingMB = ‘Dancing Script’;

 Static const String handwritingJR = ‘Kalam’;

 Static const String handwritingEW = ‘Architects Daughter’;



 Static const TextStyle mainText = TextStyle(

 fontFamily: primaryFont,

 fontSize: 12,

 height: 1.4,

 color: Color(0xFF2a2a2a),

 fontWeight: FontWeight.normal,

 );



 Static const TextStyle chapterHeading = TextStyle(

 fontFamily: primaryFont,

 fontSize: 16,

 fontWeight: FontWeight.bold,

 color: Color(0xFF1a1a1a),

 );



 Static const TextStyle pageNumber = TextStyle(

 fontFamily: primaryFont,

 fontSize: 10,

 color: Colors.black54,

 );



 Static TextStyle marginaliaMB = TextStyle(

 fontFamily: handwritingMB,

 fontSize: 10,

 color: Color(0xFF2653a3),

 fontStyle: FontStyle.italic,

 );



 Static TextStyle marginaliaJR = TextStyle(

 fontFamily: handwritingJR,

 fontSize: 9,

 color: Color(0xFF1a1a1a),

 );



 Static TextStyle marginaliaEW = TextStyle(

 fontFamily: handwritingEW,

 fontSize: 10,

 color: Color(0xFFc41e3a),

 fontWeight: FontWeight.w500,

 );

}

```



### Color Palette

```dart

Class AppColors {

 // Paper backgrounds

 Static const Color academicPaper = Color(0xFFF4E8D0);

 Static const Color academicPaperDark = Color(0xFFE8DCC0);

 Static const Color personalLetter = Color(0xFFFFFFF0);

 Static const Color policeReport = Color(0xFFF8F8FF);

 Static const Color journalPaper = Color(0xFFFFFFF0);

 Static const Color governmentMemo = Color(0xFFF5F5DC);



 // Annotation colors

 Static const Color marginaliaBlue = Color(0xFF2653a3);

 Static const Color marginaliaBlack = Color(0xFF1a1a1a);

 Static const Color marginaliaRed = Color(0xFFc41e3a);



 // Post-it colors

 Static const Color postItYellow = Color(0xFFFFFF99);

 Static const Color postItWhite = Color(0xFFFFFFFF);

 Static const Color postItManila = Color(0xFFF5F5DC);



 // UI colors

 Static const Color bookSpine = Color(0xFF8B4513);

 Static const Color bookCover = Color(0xFF654321);

 Static const Color redactionBlack = Color(0xFF000000);

 Static const Color classificationRed = Color(0xFFd32f2f);

}

```



### Book Dimensions

```dart

Class BookDimensions {

 Static const double pageAspectRatio = 11.0 / 8.5; // US Letter

 Static const double marginRatio = 0.12; // 12% margin on each side

 Static const double spineWidth = 24.0;

 Static const double pageSpacing = 8.0;



 Static Size calculatePageSize(BuildContext context, ReadingMode mode) {

 Final screenSize = MediaQuery.of(context).size;

 

 Switch (mode) {

 Case ReadingMode.singlePage:

 Final maxWidth = screenSize.width * 0.9;

 Final maxHeight = screenSize.height * 0.85;

 

 Final widthConstrainedHeight = maxWidth * pageAspectRatio;

 If (widthConstrainedHeight <= maxHeight) {

 Return Size(maxWidth, widthConstrainedHeight);

 } else {

 Return Size(maxHeight / pageAspectRatio, maxHeight);

 }

 

 Case ReadingMode.bookSpread:

 Final availableWidth = screenSize.width – spineWidth – (pageSpacing * 2);

 Final pageWidth = availableWidth / 2;

 Final pageHeight = pageWidth * pageAspectRatio;

 

 // Ensure it fits on screen

 Final maxHeight = screenSize.height * 0.85;

 If (pageHeight > maxHeight) {

 Final adjustedHeight = maxHeight;

 Final adjustedWidth = adjustedHeight / pageAspectRatio;

 Return Size(adjustedWidth, adjustedHeight);

 }

 

 Return Size(pageWidth, pageHeight);

 }

 }



 Static EdgeInsets getPageMargins(Size pageSize) {

 Final marginSize = pageSize.width * marginRatio;

 Return EdgeInsets.all(marginSize);

 }

}

```





## IMPLEMENTATION PHASES



### Phase 1: Foundation (Weeks 1-2)

**Objective**: Set up basic Flutter project structure and core layout system



**Tasks**:

- [ ] Create Flutter project with proper folder structure

- [ ] Add required dependencies (provider, shared\_preferences, etc.)

- [ ] Implement DocumentType enum and basic data models

- [ ] Create AcademicPaperBackground widget

- [ ] Build basic DocumentPage widget with fixed text layout

- [ ] Test layout integrity across different screen sizes

- [ ] Implement basic navigation between pages



**Key Files to Create**:

```

Lib/

├── main.dart

├── models/

│ ├── document\_page\_data.dart

│ ├── marginalia\_note.dart

│ ├── post\_it\_annotation.dart

│ └── redaction\_data.dart

├── widgets/

│ ├── document\_page.dart

│ └── backgrounds/

│ └── academic\_paper\_background.dart

├── providers/

│ ├── document\_state.dart

│ └── access\_provider.dart

└── utils/

 ├── constants.dart

 └── typography.dart

```



**Success Criteria**:

- Fixed page layout maintains 2.3cm margins

- Main text never reflows or shifts

- Pages can be navigated with swipe gestures

- Layout works on both mobile and desktop



### Phase 2: Temporal Annotation System (Weeks 3-4)

**Objective**: Implement the 1999/2000 temporal annotation rule



**Tasks**:

- [ ] Create FixedMarginaliaWidget for pre-2000 annotations

- [ ] Implement character-specific fonts (MB, JR, EW)

- [ ] Build DraggablePostItWidget for post-2000 annotations

- [ ] Add annotation position persistence

- [ ] Test margin boundary enforcement

- [ ] Implement tap-to-enlarge for marginalia

- [ ] Add post-it context menus and interactions



**Key Features**:

- Date-based annotation type detection

- Margin boundary enforcement for marginalia

- Draggable post-its with realistic shadows and rotation

- Position persistence across app sessions

- Author-specific styling and fonts



**Success Criteria**:

- Pre-2000 annotations stay fixed in margins

- Post-2000 annotations can be dragged anywhere

- Position changes persist between app launches

- Different authors have distinct visual styles



### Phase 3: Redaction & Interactivity (Weeks 5-6)

**Objective**: Implement progressive content revelation system



**Tasks**:

- [ ] Create RedactableTextWidget with black bars

- [ ] Implement unlock dialogs and payment simulation

- [ ] Add zoom and pan functionality with InteractiveViewer

- [ ] Build government stamp overlays

- [ ] Create page flip animations for book mode

- [ ] Implement access level management

- [ ] Add unlock animations (fade-in effect)



**Key Features**:

- Tiered unlocking system (classified, restricted, top secret)

- Smooth reveal animations

- Payment integration simulation

- Zoom/pan without breaking layout

- Realistic government stamps



**Success Criteria**:

- Redacted content shows as black bars initially

- Unlock dialogs display appropriate pricing

- Reveal animations are smooth and satisfying

- Zoom/pan maintains annotation positions

- Access levels properly restrict content



### Phase 4: Book Experience (Weeks 7-8)

**Objective**: Implement realistic book appearance and reading modes



**Tasks**:

- [ ] Create BookContainer widget with spine and shadows

- [ ] Implement reading mode toggle (single page vs book spread)

- [ ] Add page flip animations with 3D effects

- [ ] Build responsive layout system for different devices

- [ ] Create book-specific visual effects (spine shadows, page curves)

- [ ] Implement touch-friendly navigation

- [ ] Add page numbering and progress indicators



**Key Features**:

- Dual reading modes with automatic recommendations

- Realistic book spine and shadows

- 3D page flip animations

- Device-specific optimizations

- Book-like visual effects



**Success Criteria**:

- Book spread mode works well on tablets/desktop

- Single page mode optimized for mobile

- Page flips have realistic 3D animation

- Visual book effects enhance authenticity

- Mode switching is smooth and intuitive



### Phase 5: Document Variety & Polish (Weeks 9-10)

**Objective**: Add supplementary document types and final polish



**Tasks**:

- [ ] Implement different document backgrounds (letters, reports, journals)

- [ ] Create document-specific layouts and styling

- [ ] Add authentic aging effects and textures

- [ ] Implement cross-document annotation consistency

- [ ] Performance optimization and memory management

- [ ] Add accessibility features

- [ ] Final testing and bug fixes



**Key Features**:

- Multiple document background types

- Authentic paper textures and aging effects

- Seamless transitions between document types

- Optimized performance for large documents

- Accessibility support



**Success Criteria**:

- Each document type has authentic appearance

- Transitions between document types are smooth

- App maintains 60fps during all interactions

- Memory usage remains reasonable for long documents

- Accessibility features work properly





## CODE EXAMPLES



### Main Application Setup

```dart

// main.dart

Import ‘package:flutter/material.dart’;

Import ‘package:provider/provider.dart’;

Import ‘providers/document\_state.dart’;

Import ‘providers/access\_provider.dart’;

Import ‘screens/book\_reader\_screen.dart’;

Import ‘utils/typography.dart’;



Void main() {

 runApp(BlackthornManorApp());

}



Class BlackthornManorApp extends StatelessWidget {

 @override

 Widget build(BuildContext context) {

 Return MultiProvider(

 Providers: [

 ChangeNotifierProvider(create: (\_) => DocumentState()),

 ChangeNotifierProvider(create: (\_) => AccessProvider()),

 ],

 Child: MaterialApp(

 Title: ‘Blackthorn Manor Archive’,

 Theme: \_buildAppTheme(),

 Home: BookReaderScreen(),

 debugShowCheckedModeBanner: false,

 ),

 );

 }



 ThemeData \_buildAppTheme() {

 Return ThemeData(

 primarySwatch: Colors.brown,

 scaffoldBackgroundColor: AppColors.bookCover,

 fontFamily: AppTypography.primaryFont,

 textTheme: TextTheme(

 bodyLarge: AppTypography.mainText,

 headlineMedium: AppTypography.chapterHeading,

 ),

 );

 }

}

```



### Book Reader Screen

```dart

// screens/book\_reader\_screen.dart

Import ‘package:flutter/material.dart’;

Import ‘package:provider/provider.dart’;

Import ‘../providers/document\_state.dart’;

Import ‘../widgets/book\_container.dart’;

Import ‘../widgets/reading\_mode\_toggle.dart’;

Import ‘../widgets/navigation\_controls.dart’;

Import ‘../services/content\_loader.dart’;



Class BookReaderScreen extends StatefulWidget {

 @override

 \_BookReaderScreenState createState() => \_BookReaderScreenState();

}



Class \_BookReaderScreenState extends State {

 List \_pages = [];

 Bool \_isLoading = true;



 @override

 Void initState() {

 Super.initState();

 \_loadContent();

 Context.read().loadFromPreferences();

 Context.read().loadFromPreferences();

 }



 Future \_loadContent() async {

 Try {

 Final pages = await ContentLoader.loadAllPages();

 setState(() {

 \_pages = pages;

 \_isLoading = false;

 });

 } catch (e) {

 Print(‘Error loading content: $e’);

 setState(() {

 \_isLoading = false;

 });

 }

 }



 @override

 Widget build(BuildContext context) {

 If (\_isLoading) {

 Return Scaffold(

 backgroundColor: AppColors.bookCover,

 body: Center(

 child: Column(

 mainAxisAlignment: MainAxisAlignment.center,

 children: [

 CircularProgressIndicator(

 valueColor: AlwaysStoppedAnimation(Colors.amber),

 ),

 SizedBox(height: 16),

 Text(

 ‘Loading classified documents...’,

 Style: TextStyle(color: Colors.white),

 ),

 ],

 ),

 ),

 );

 }



 Return Scaffold(

 backgroundColor: AppColors.bookCover,

 body: SafeArea(

 child: Column(

 children: [

 // Reading mode toggle

 ReadingModeToggle(),

 

 // Main book container

 Expanded(

 Child: Consumer(

 Builder: (context, documentState, child) {

 Return BookContainer(

 Pages: \_pages,

 currentPageIndex: documentState.currentPage,

 readingMode: documentState.readingMode,

 onPageChanged: (index) {

 documentState.setCurrentPage(index);

 },

 );

 },

 ),

 ),

 

 // Navigation controls

 NavigationControls(

 totalPages: \_pages.length,

 ),

 ],

 ),

 ),

 );

 }

}

```



### Content Loader Service

```dart

// services/content\_loader.dart

Import ‘dart:convert’;

Import ‘package:flutter/services.dart’;

Import ‘../models/document\_page\_data.dart’;



Class ContentLoader {

 Static Future> loadAllPages() async {

 Try {

 // Load main manuscript pages

 Final manuscriptPages = await \_loadManuscriptPages();

 

 // Load supplementary documents

 Final supplementaryPages = await \_loadSupplementaryDocuments();

 

 // Combine and sort by page number

 Final allPages = [...manuscriptPages, ...supplementaryPages];

 allPages.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

 

 return allPages;

 } catch (e) {

 Print(‘Error loading pages: $e’);

 Return [];

 }

 }



 Static Future> \_loadManuscriptPages() async {

 Final jsonString = await rootBundle.loadString(‘assets/data/manuscript\_pages.json’);

 Final jsonData = jsonDecode(jsonString) as List;

 

 Return jsonData

 .map((pageJson) => DocumentPageData.fromJson(pageJson))

 .toList();

 }



 Static Future> \_loadSupplementaryDocuments() async {

 Final jsonString = await rootBundle.loadString(‘assets/data/supplementary\_documents.json’);

 Final jsonData = jsonDecode(jsonString) as List;

 

 Return jsonData

 .map((docJson) => DocumentPageData.fromJson(docJson))

 .toList();

 }



 // Helper method to create sample data for testing

 Static List createSamplePages() {

 Return [

 DocumentPageData(

 pageNumber: 1,

 documentType: DocumentType.academic,

 mainText: ‘’’

# CHAPTER I: INTRODUCTION AND HISTORICAL CONTEXT



Blackthorn Manor represents one of the finest examples of Victorian Gothic Revival architecture in the country. Completed in 1871, the house was commissioned by Sir William Blackthorn following his return from extensive travels in Egypt and the Near East.



Historical records indicate that Sir William employed over two hundred workers during the four-year construction period, with an unusually high turnover rate attributed to the demanding working conditions and Sir William’s exacting standards.

 ‘’’,

 Marginalia: [

 MarginaliaNote(

 Id: ‘mb\_001’,

 Author: ‘MB’,

 Date: DateTime(1987, 3, 15),

 Text: ‘The “demanding conditions” were actually dimensional exposure symptoms. Walter had to replace workers every few weeks to prevent long-term effects.’,

 Position: Offset(20, 150),

 fontStyle: ‘Dancing Script’,

 color: AppColors.marginaliaBlue,

 ),

 ],

 postIts: [

 PostItAnnotation(

 Id: ‘sw\_001’,

 Author: ‘SW’,

 Date: DateTime(2024, 5, 1),

 Text: ‘Found Walter\’s journal – the “travels in Egypt” involved forbidden archaeological sites. He brought something back with him.’,

 currentPosition: Offset(200, 300),

 backgroundColor: AppColors.postItYellow,

 rotation: -0.05,

 size: PostItSize.medium,

 ),

 ],

 Redactions: [

 RedactionData(

 Id: ‘red\_001’,

 Position: Offset(100, 250),

 Width: 200,

 Height: 20,

 barCount: 15,

 unlockKey: ‘egypt\_expedition\_details’,

 secretText: ‘including his discovery of sealed chambers beneath the Temple of Hathor containing artifacts of unknown origin’,

 requiredLevel: AccessLevel.classified,

 ),

 ],

 ),

 // Add more sample pages as needed

 ];

 }

}

```



### Asset Requirements

```yaml

# pubspec.yaml

Dependencies:

 Flutter:

 Sdk: flutter

 Provider: ^6.0.5

 Shared\_preferences: ^2.2.0

 Path\_provider: ^2.1.0

 Flutter\_svg: ^2.0.7



Fonts:

Family: Courier Prime

 Fonts:

 - asset: assets/fonts/CourierPrime-Regular.ttf

 - asset: assets/fonts/CourierPrime-Bold.ttf

 Weight: 700

Family: Dancing Script

 Fonts:

 - asset: assets/fonts/DancingScript-Regular.ttf

 - asset: assets/fonts/DancingScript-Bold.ttf

 Weight: 700

Family: Kalam

 Fonts:

 - asset: assets/fonts/Kalam-Regular.ttf

 - asset: assets/fonts/Kalam-Bold.ttf

 Weight: 700

Family: Architects Daughter

 Fonts:

Asset: assets/fonts/ArchitectsDaughter-Regular.ttf



Flutter:

 Assets:

 - assets/data/

 - assets/textures/

 - assets/images/

 - assets/documents/

```





## CRITICAL SUCCESS CRITERIA



### Layout Integrity

- Main text never displaced by annotations

- 2.3cm margins consistently maintained

- Fixed proportions across all screen sizes

- Content completeness preserved



### Temporal Authenticity

- Clear visual distinction between pre/post-2000 annotations

- Date-based behavior enforcement

- Period-appropriate styling and interactions

- Historical progression narrative maintained



### Interactive Responsiveness

- All taps respond within 100ms

- Smooth drag interactions for post-its

- Fluid zoom/pan without layout breaks

- Satisfying unlock animations



### Visual Authenticity

- Realistic document appearance across all types

- Authentic aging effects and paper textures

- Proper book-like visual elements

- Government document styling accuracy



### Monetization Clarity

- Clear pricing for different access levels

- Obvious value proposition for upgrades

- Smooth purchase flow

- Proper content protection



This implementation guide provides everything needed to build the Blackthorn Manor interactive document experience in Flutter. Each phase builds upon the previous one, ensuring a solid foundation while maintaining the authentic document feel that makes this project unique.



