import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/reading_experience_service.dart';

class ReadingModePreferencesWidget extends StatefulWidget {
  final VoidCallback? onPreferencesChanged;

  const ReadingModePreferencesWidget({
    super.key,
    this.onPreferencesChanged,
  });

  @override
  State<ReadingModePreferencesWidget> createState() => _ReadingModePreferencesWidgetState();
}

class _ReadingModePreferencesWidgetState extends State<ReadingModePreferencesWidget>
    with TickerProviderStateMixin {
  final ReadingExperienceService _readingService = ReadingExperienceService();
  
  late AnimationController _previewController;
  late AnimationController _settingsController;
  late Animation<double> _previewAnimation;
  late Animation<double> _settingsAnimation;
  
  ReadingPreferences _preferences = ReadingPreferences();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    _previewController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _settingsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _previewAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _previewController, curve: Curves.easeInOut),
    );
    
    _settingsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _settingsController, curve: Curves.easeOutBack),
    );
    
    _initializePreferences();
  }

  @override
  void dispose() {
    _previewController.dispose();
    _settingsController.dispose();
    super.dispose();
  }

  Future<void> _initializePreferences() async {
    await _readingService.initialize();
    
    setState(() {
      _preferences = ReadingPreferences(); // Load current preferences
      _isLoading = false;
    });
    
    _startAnimations();
  }

  void _startAnimations() {
    _previewController.forward();
    
    Future.delayed(const Duration(milliseconds: 200), () {
      _settingsController.forward();
    });
  }

  void _updatePreferences() {
    _readingService.updatePreferences(_preferences);
    widget.onPreferencesChanged?.call();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Preview section
          _buildPreviewSection(),
          
          const SizedBox(height: 24),
          
          // Settings sections
          _buildReadingModeSection(),
          
          const SizedBox(height: 24),
          
          _buildTypographySection(),
          
          const SizedBox(height: 24),
          
          _buildAccessibilitySection(),
          
          const SizedBox(height: 24),
          
          _buildAdvancedSection(),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    return AnimatedBuilder(
      animation: _previewAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (_previewAnimation.value * 0.2),
          child: Opacity(
            opacity: _previewAnimation.value,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildPreviewContent(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewContent() {
    final typography = TypographyConfig(
      baseFontSize: 18.0 * _preferences.fontSizeMultiplier,
      lineHeight: 1.8 * _preferences.lineHeightMultiplier,
      letterSpacing: 0.3,
      paragraphSpacing: 20.0 * _preferences.spacingMultiplier,
      fontWeight: FontWeight.w400,
      fontFamily: 'Charter',
      color: Colors.black,
    );
    
    final readingMode = _getReadingModeConfig(_preferences.readingMode);
    
    return Container(
      color: readingMode.backgroundColor,
      padding: EdgeInsets.all(20.0 * readingMode.marginMultiplier),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.preview, size: 16, color: Colors.blue[600]),
                const SizedBox(width: 6),
                Text(
                  'Preview',
                  style: TextStyle(
                    fontSize: typography.baseFontSize * 0.75,
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: typography.paragraphSpacing),
          
          // Sample heading
          Text(
            'Chapter 1: The Investigation Begins',
            style: TextStyle(
              fontSize: typography.baseFontSize * 1.5,
              fontWeight: FontWeight.bold,
              color: _adjustColorForReadingMode(typography.color, readingMode),
              height: 1.3,
            ),
          ),
          
          SizedBox(height: typography.paragraphSpacing * 0.75),
          
          // Sample paragraph
          Text(
            'The morning mist clung to the ancient stones of Blackthorn Manor like whispered secrets from centuries past. Professor Harold Finch adjusted his spectacles and opened his leather-bound notebook, unaware that this seemingly routine architectural survey would become something far more extraordinary.',
            style: TextStyle(
              fontSize: typography.baseFontSize,
              height: typography.lineHeight,
              letterSpacing: typography.letterSpacing,
              fontWeight: typography.fontWeight,
              fontFamily: typography.fontFamily,
              color: _adjustColorForReadingMode(typography.color, readingMode),
            ),
            textAlign: TextAlign.justify,
          ),
          
          SizedBox(height: typography.paragraphSpacing * 0.5),
          
          // Sample annotation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.blue,
                  child: const Text(
                    'M',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'MB: Something feels different about this place... - 1963',
                    style: TextStyle(
                      fontSize: typography.baseFontSize * 0.9,
                      color: _adjustColorForReadingMode(Colors.blue[700]!, readingMode),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingModeSection() {
    return AnimatedBuilder(
      animation: _settingsAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _settingsAnimation.value)),
          child: Opacity(
            opacity: _settingsAnimation.value,
            child: _buildSection(
              'Reading Mode',
              Icons.brightness_6,
              [
                _buildReadingModeSelector(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReadingModeSelector() {
    final modes = [
      ReadingModeOption(
        mode: ReadingMode.standard,
        title: 'Standard',
        description: 'Default white background',
        icon: Icons.brightness_high,
        color: Colors.blue,
      ),
      ReadingModeOption(
        mode: ReadingMode.comfortable,
        title: 'Comfortable',
        description: 'Warm, easy on eyes',
        icon: Icons.wb_sunny,
        color: Colors.orange,
      ),
      ReadingModeOption(
        mode: ReadingMode.focused,
        title: 'Focused',
        description: 'Minimalist, distraction-free',
        icon: Icons.center_focus_strong,
        color: Colors.green,
      ),
      ReadingModeOption(
        mode: ReadingMode.night,
        title: 'Night',
        description: 'Dark mode for low light',
        icon: Icons.nights_stay,
        color: Colors.indigo,
      ),
      ReadingModeOption(
        mode: ReadingMode.sepia,
        title: 'Sepia',
        description: 'Classic book-like feel',
        icon: Icons.auto_stories,
        color: Colors.brown,
      ),
    ];

    return Column(
      children: modes.map((option) => _buildReadingModeOption(option)).toList(),
    );
  }

  Widget _buildReadingModeOption(ReadingModeOption option) {
    final isSelected = _preferences.readingMode == option.mode;
    final config = _getReadingModeConfig(option.mode);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _preferences.readingMode = option.mode;
          });
          _updatePreferences();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? option.color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? option.color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 32,
                decoration: BoxDecoration(
                  color: config.backgroundColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Center(
                  child: Text(
                    'Aa',
                    style: TextStyle(
                      color: config.textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? option.color : Colors.grey[800],
                      ),
                    ),
                    Text(
                      option.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              Icon(
                option.icon,
                color: isSelected ? option.color : Colors.grey[400],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypographySection() {
    return AnimatedBuilder(
      animation: _settingsAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - _settingsAnimation.value)),
          child: Opacity(
            opacity: _settingsAnimation.value * 0.9,
            child: _buildSection(
              'Typography',
              Icons.text_fields,
              [
                _buildSliderSetting(
                  'Font Size',
                  _preferences.fontSizeMultiplier,
                  0.8,
                  1.5,
                  (value) {
                    setState(() {
                      _preferences.fontSizeMultiplier = value;
                    });
                    _updatePreferences();
                  },
                  formatValue: (value) => '${(value * 100).toInt()}%',
                ),
                
                _buildSliderSetting(
                  'Line Height',
                  _preferences.lineHeightMultiplier,
                  0.8,
                  2.0,
                  (value) {
                    setState(() {
                      _preferences.lineHeightMultiplier = value;
                    });
                    _updatePreferences();
                  },
                  formatValue: (value) => '${(value * 100).toInt()}%',
                ),
                
                _buildSliderSetting(
                  'Paragraph Spacing',
                  _preferences.spacingMultiplier,
                  0.5,
                  2.0,
                  (value) {
                    setState(() {
                      _preferences.spacingMultiplier = value;
                    });
                    _updatePreferences();
                  },
                  formatValue: (value) => '${(value * 100).toInt()}%',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccessibilitySection() {
    return AnimatedBuilder(
      animation: _settingsAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _settingsAnimation.value)),
          child: Opacity(
            opacity: _settingsAnimation.value * 0.8,
            child: _buildSection(
              'Accessibility',
              Icons.accessibility,
              [
                _buildSwitchSetting(
                  'Adaptive Typography',
                  'Automatically adjust text for different content types',
                  _preferences.adaptiveTypography,
                  (value) {
                    setState(() {
                      _preferences.adaptiveTypography = value;
                    });
                    _updatePreferences();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdvancedSection() {
    return AnimatedBuilder(
      animation: _settingsAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 60 * (1 - _settingsAnimation.value)),
          child: Opacity(
            opacity: _settingsAnimation.value * 0.7,
            child: _buildSection(
              'Engagement',
              Icons.psychology,
              [
                _buildSwitchSetting(
                  'Reading Goals',
                  'Track reading progress with daily, weekly, and monthly goals',
                  _preferences.readingGoalsEnabled,
                  (value) {
                    setState(() {
                      _preferences.readingGoalsEnabled = value;
                    });
                    _updatePreferences();
                  },
                ),
                
                _buildSwitchSetting(
                  'Achievements',
                  'Unlock achievements for reading milestones',
                  _preferences.achievementsEnabled,
                  (value) {
                    setState(() {
                      _preferences.achievementsEnabled = value;
                    });
                    _updatePreferences();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.blue[600], size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          
          // Section content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSetting(
    String title,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    String Function(double)? formatValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              formatValue?.call(value) ?? value.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.blue[400],
            inactiveTrackColor: Colors.grey[300],
            thumbColor: Colors.blue[600],
            overlayColor: Colors.blue[100],
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) * 10).round(),
            onChanged: onChanged,
          ),
        ),
        
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String description,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.blue[600],
            ),
          ],
        ),
        
        const SizedBox(height: 16),
      ],
    );
  }

  ReadingModeConfig _getReadingModeConfig(ReadingMode mode) {
    switch (mode) {
      case ReadingMode.standard:
        return ReadingModeConfig(
          backgroundColor: Colors.white,
          textColor: Colors.black,
          marginMultiplier: 1.0,
          contrastBoost: 0.0,
          brightness: 1.0,
        );
      case ReadingMode.comfortable:
        return ReadingModeConfig(
          backgroundColor: const Color(0xFFFFFDF7),
          textColor: const Color(0xFF2C2C2C),
          marginMultiplier: 1.2,
          contrastBoost: 0.1,
          brightness: 0.95,
        );
      case ReadingMode.focused:
        return ReadingModeConfig(
          backgroundColor: const Color(0xFFF8F8F6),
          textColor: const Color(0xFF1A1A1A),
          marginMultiplier: 1.5,
          contrastBoost: 0.2,
          brightness: 0.9,
        );
      case ReadingMode.night:
        return ReadingModeConfig(
          backgroundColor: const Color(0xFF1A1A1A),
          textColor: const Color(0xFFE0E0E0),
          marginMultiplier: 1.3,
          contrastBoost: 0.3,
          brightness: 0.8,
        );
      case ReadingMode.sepia:
        return ReadingModeConfig(
          backgroundColor: const Color(0xFFF4F1E8),
          textColor: const Color(0xFF5C4B37),
          marginMultiplier: 1.1,
          contrastBoost: 0.15,
          brightness: 0.92,
        );
    }
  }

  Color _adjustColorForReadingMode(Color baseColor, ReadingModeConfig readingMode) {
    if (readingMode.backgroundColor == Colors.white) {
      return baseColor;
    }
    
    // Adjust color for dark/night modes
    if (readingMode.backgroundColor.computeLuminance() < 0.5) {
      return readingMode.textColor;
    }
    
    return baseColor;
  }
}

// Data models
class ReadingModeOption {
  final ReadingMode mode;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  ReadingModeOption({
    required this.mode,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}