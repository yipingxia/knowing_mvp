import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting the current date
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/journal_entry.dart';
import '../models/recommendation.dart';
import '../services/openai_service.dart';
import '../services/recommendations_service.dart';
import '../services/daily_log_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class InteractiveInputScreen extends StatefulWidget {
  final DateTime selectedDate;
  final JournalEntry? initialEntry;
  
  const InteractiveInputScreen({
    super.key,
    required this.selectedDate,
    this.initialEntry,
  });

  @override
  State<InteractiveInputScreen> createState() => _InteractiveInputScreenState();
}

class _InteractiveInputScreenState extends State<InteractiveInputScreen> {
  double? _energyLevel; // Remove default value
  String _phase = ''; // Will be populated from daily log
  int? _sleepQualityIndex; // Remove default value
  String _exercise = '';
  String _emotion = '';
  String _symptoms = '';
  String _nutrition = '';
  String _notes = '';
  Set<String> _selectedStressors = {};

  // Controllers for text fields
  late final TextEditingController _exerciseController;
  late final TextEditingController _emotionController;
  late final TextEditingController _symptomsController;
  late final TextEditingController _nutritionController;
  late final TextEditingController _notesController;

  final List<String> _sleepQualities = ['Poor', 'Barely Enough', 'Fair', 'Good', 'Rested'];

  final OpenAIService _openAIService = OpenAIService();
  bool _isAnalyzing = false;
  bool _isLoadingRecommendations = true;
  Recommendation? _recommendation;
  late final RecommendationsService _recommendationsService;
  late final DailyLogService _dailyLogService;
  StreamSubscription<Recommendation?>? _recommendationsSubscription;

  // Add this list of stressors
  final List<String> _stressors = [
    'Work stress',
    'Relationships',
    'Social/peer pressure',
    'Overthinking',
    'Lack of rest',
    'Pain or discomfort',
    'Health concerns',
    'Financial stress',
    'Time management',
    'Food/exercise',
    'Technology overload',
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize services
    _recommendationsService = RecommendationsService(FirebaseFirestore.instance);
    _dailyLogService = DailyLogService(FirebaseFirestore.instance);
    
    // Initialize controllers with empty values first
    _exerciseController = TextEditingController();
    _emotionController = TextEditingController();
    _symptomsController = TextEditingController();
    _nutritionController = TextEditingController();
    _notesController = TextEditingController();

    // Initialize with data from initial entry if provided
    if (widget.initialEntry != null) {
      _energyLevel = widget.initialEntry!.energyLevel;
      _phase = widget.initialEntry!.phase;
      _sleepQualityIndex = widget.initialEntry!.sleepQualityIndex;
      _exercise = widget.initialEntry!.exercise;
      _emotion = widget.initialEntry!.emotion;
      _symptoms = widget.initialEntry!.symptoms;
      _nutrition = widget.initialEntry!.nutrition;
      _notes = widget.initialEntry!.notes;
      _selectedStressors = Set<String>.from(widget.initialEntry!.stressors);
      
      // Update controllers
      _exerciseController.text = _exercise;
      _emotionController.text = _emotion;
      _symptomsController.text = _symptoms;
      _nutritionController.text = _nutrition;
      _notesController.text = _notes;
    }

    // Load today's log and recommendations
    _loadTodayLog();
    _watchRecommendations();
  }

  Future<void> _loadTodayLog() async {
    try {
      final todayLog = await _dailyLogService.getTodayLog();
      if (todayLog != null && mounted) {
        setState(() {
          // Always update phase from today's log
          _phase = todayLog.phase;
          
          // Only update other fields if no initial entry was provided
          if (widget.initialEntry == null) {
            _energyLevel = todayLog.energyLevel;
            _sleepQualityIndex = todayLog.sleepQualityIndex;
            _selectedStressors = Set<String>.from(todayLog.stressors);
            
            // Parse the notes field to extract individual components
            final notes = todayLog.notes;
            if (notes.isNotEmpty) {
              final lines = notes.split('\n');
              for (final line in lines) {
                if (line.startsWith('Nutrition: ')) {
                  _nutrition = line.substring('Nutrition: '.length);
                  _nutritionController.text = _nutrition;
                } else if (line.startsWith('Exercise: ')) {
                  _exercise = line.substring('Exercise: '.length);
                  _exerciseController.text = _exercise;
                } else if (line.startsWith('Emotion: ')) {
                  _emotion = line.substring('Emotion: '.length);
                  _emotionController.text = _emotion;
                } else if (line.startsWith('Symptoms: ')) {
                  _symptoms = line.substring('Symptoms: '.length);
                  _symptomsController.text = _symptoms;
                } else if (line.startsWith('\nAdditional Notes:\n')) {
                  _notes = line.substring('\nAdditional Notes:\n'.length);
                  _notesController.text = _notes;
                }
              }
            }
          } else {
            // If we have an initial entry, use its notes and stressors
            _notes = widget.initialEntry!.notes;
            _notesController.text = _notes;
            _selectedStressors = Set<String>.from(widget.initialEntry!.stressors);
          }
        });
      }
    } catch (e) {
      print('Error loading today\'s log: $e');
      // Don't show error to user, just leave the form empty
    }
  }

  void _watchRecommendations() {
    _recommendationsSubscription = _recommendationsService
        .watchRecommendations(widget.selectedDate)
        .listen(
          (recommendation) {
            if (mounted) {
              setState(() {
                _recommendation = recommendation;
                _isLoadingRecommendations = false;
              });
            }
          },
          onError: (error) {
            print('Error watching recommendations: $error');
            if (mounted) {
              setState(() {
                _isLoadingRecommendations = false;
              });
            }
          },
        );
  }

  @override
  void dispose() {
    _recommendationsSubscription?.cancel();
    _exerciseController.dispose();
    _emotionController.dispose();
    _symptomsController.dispose();
    _nutritionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Update controllers after parsing
  void _updateControllers() {
    _exerciseController.text = _exercise;
    _emotionController.text = _emotion;
    _symptomsController.text = _symptoms;
    _nutritionController.text = _nutrition;
    _notesController.text = _notes;
  }

  Future<void> _saveEntry() async {
    setState(() => _isAnalyzing = true);
    
    try {
      // Create initial entry
      final entry = JournalEntry(
        date: widget.selectedDate,
        phase: _phase,
        energyLevel: _energyLevel ?? 0,
        sleepQualityIndex: _sleepQualityIndex ?? 0,
        exercise: _exercise,
        emotion: _emotion,
        symptoms: _symptoms,
        nutrition: _nutrition,
        notes: _notesController.text == widget.initialEntry?.notes ? 
               widget.initialEntry!.notes : 
               _notes,
        stressors: _selectedStressors.toList(),
      );

      JournalEntry updatedEntry = entry;

      // If there's nutrition text, analyze it
      if (_nutrition.isNotEmpty) {
        try {
          final nutritionAnalysis = await _openAIService.analyzeNutrition(_nutrition);
          updatedEntry = updatedEntry.copyWith(
            fiberGrams: nutritionAnalysis['fiber'],
            proteinGrams: nutritionAnalysis['protein'],
          );
        } catch (e) {
          print('Error analyzing nutrition: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unable to analyze nutrition content. Saving entry without analysis.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }

      // If there's exercise text, analyze it for body stress level
      if (_exercise.isNotEmpty) {
        try {
          final exerciseAnalysis = await _openAIService.analyzeNutrition(
            _exercise,
            isExerciseOnly: true,
          );
          if (exerciseAnalysis['bodyStressLevel'] != null) {
            updatedEntry = updatedEntry.copyWith(
              bodyStressLevel: exerciseAnalysis['bodyStressLevel'].toDouble(),
            );
          }
        } catch (e) {
          print('Error analyzing exercise stress level: $e');
          // Continue without body stress level if analysis fails
        }
      }

      // Create the daily log entry with the original notes preserved
      final dailyLogEntry = JournalEntry(
        date: widget.selectedDate,
        phase: _phase,
        energyLevel: _energyLevel ?? 0,
        sleepQualityIndex: _sleepQualityIndex ?? 0,
        notes: _notesController.text == widget.initialEntry?.notes ? 
               widget.initialEntry!.notes : 
               _notes,
        exercise: _exercise,
        emotion: _emotion,
        symptoms: _symptoms,
        nutrition: _nutrition,
        fiberGrams: updatedEntry.fiberGrams,
        proteinGrams: updatedEntry.proteinGrams,
        bodyStressLevel: updatedEntry.bodyStressLevel,
        stressors: _selectedStressors.toList(),
      );

      // Save to daily logs
      await _dailyLogService.saveLog(dailyLogEntry);
      
      // Return the entry with any successful analyses
      Navigator.pop(context, updatedEntry);
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat.yMMMMd().format(widget.selectedDate);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Center(
          child: ConstrainedBox(
            constraints: AppTheme.maxWidthConstraint,
            child: Column(
              children: [
                Text(
                  'Daily Check-in',
                  style: AppTheme.titleStyle,
                ),
                Text(
                  formattedDate,
                  style: AppTheme.dateStyle,
                ),
              ],
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        child: Center(
          child: ConstrainedBox(
            constraints: AppTheme.maxWidthConstraint,
            child: SingleChildScrollView(
              padding: AppTheme.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isAnalyzing)
                    const Center(child: CircularProgressIndicator())
                  else
                    const SizedBox.shrink(),
                  // Energy and Sleep Quality section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Energy Level section
                      Expanded(
                        child: Column(
                          children: [
                            // Energy indicator
                            Text(
                              _energyLevel != null ? '${_energyLevel!.round()}%' : '--',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            const Text(
                              'Energy Level',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Vertical Energy Slider
                            SizedBox(
                              height: 200,
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 4.0,
                                    trackShape: const RoundedRectSliderTrackShape(),
                                    activeTrackColor: Colors.black87,
                                    inactiveTrackColor: Colors.grey[300],
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 12.0,
                                    ),
                                    thumbColor: Colors.white,
                                    overlayColor: Colors.black.withAlpha(32),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 28.0),
                                  ),
                                  child: Slider(
                                    value: _energyLevel ?? 0,
                                    min: 0,
                                    max: 100,
                                    onChanged: (value) {
                                      setState(() {
                                        _energyLevel = value;
                                      });
                                    },
                                    onChangeStart: (value) {
                                      if (_energyLevel == null) {
                                        setState(() {
                                          _energyLevel = value;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Sleep Quality section
                      Expanded(
                        child: Column(
                          children: [
                            // Sleep quality indicator
                            Text(
                              _sleepQualityIndex != null ? _sleepQualities[_sleepQualityIndex!] : '--',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            const Text(
                              'Sleep Quality',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Vertical Sleep Quality Slider
                            SizedBox(
                              height: 200,
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 4.0,
                                    trackShape: const RoundedRectSliderTrackShape(),
                                    activeTrackColor: Colors.black87,
                                    inactiveTrackColor: Colors.grey[300],
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 12.0,
                                    ),
                                    thumbColor: Colors.white,
                                    overlayColor: Colors.black.withAlpha(32),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 28.0),
                                    tickMarkShape: const RoundSliderTickMarkShape(),
                                    activeTickMarkColor: Colors.black87,
                                    inactiveTickMarkColor: Colors.grey[300],
                                    valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
                                    valueIndicatorColor: Colors.black87,
                                    valueIndicatorTextStyle: const TextStyle(color: Colors.white),
                                  ),
                                  child: Slider(
                                    value: _sleepQualityIndex?.toDouble() ?? 0,
                                    min: 0,
                                    max: 4,
                                    divisions: 4,
                                    label: _sleepQualityIndex != null ? _sleepQualities[_sleepQualityIndex!] : 'Select',
                                    onChanged: (value) {
                                      setState(() {
                                        _sleepQualityIndex = value.round();
                                      });
                                    },
                                    onChangeStart: (value) {
                                      if (_sleepQualityIndex == null) {
                                        setState(() {
                                          _sleepQualityIndex = value.round();
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Input Fields Grid
                  Column(
                    children: [
                      // First row: Nutrition and Exercise
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputCard('Nutrition', _nutrition, (value) => setState(() => _nutrition = value)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInputCard('Exercise', _exercise, (value) => setState(() => _exercise = value)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Second row: Emotion and Symptoms
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputCard('Emotion', _emotion, (value) => setState(() => _emotion = value)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInputCard('Symptoms', _symptoms, (value) => setState(() => _symptoms = value)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Third row: Stressors
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Stressors',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _stressors.map((stressor) {
                                final isSelected = _selectedStressors.contains(stressor);
                                return FilterChip(
                                  label: Text(stressor),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedStressors.add(stressor);
                                      } else {
                                        _selectedStressors.remove(stressor);
                                      }
                                    });
                                  },
                                  backgroundColor: Colors.white,
                                  selectedColor: Colors.black87,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontSize: 12,
                                  ),
                                  checkmarkColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: isSelected ? Colors.black87 : Colors.grey[300]!,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Notes Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notes',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Add any additional notes...',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                          onChanged: (value) {
                            setState(() => _notes = value);
                          },
                          controller: _notesController,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isAnalyzing ? null : _saveEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isAnalyzing
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Save Entry',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recommendations section
                  if (_isLoadingRecommendations)
                    Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Loading your personalized recommendations...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_recommendation != null)
                    ExpansionTile(
                      title: Text(
                        'Your Recommendations',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        'Current Phase: ${_recommendation!.currentPhase}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      initiallyExpanded: false,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Text(
                            _recommendation!.poeticMessage,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        ..._recommendation!.recommendations.entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.key.replaceAll('_', ' ').toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...entry.value.map(
                                  (recommendation) => Padding(
                                    padding: const EdgeInsets.only(
                                      left: 16,
                                      bottom: 8,
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('• '),
                                        Expanded(
                                          child: Text(
                                            recommendation,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard(String title, String value, Function(String) onChanged) {
    TextEditingController controller;
    switch (title.toLowerCase()) {
      case 'exercise':
        controller = _exerciseController;
        break;
      case 'emotion':
        controller = _emotionController;
        break;
      case 'symptoms':
        controller = _symptomsController;
        break;
      case 'nutrition':
        controller = _nutritionController;
        break;
      default:
        controller = TextEditingController(text: value);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Enter ${title.toLowerCase()}...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontSize: 14,
              ),
              onChanged: onChanged,
              controller: controller,
            ),
          ),
        ],
      ),
    );
  }
}