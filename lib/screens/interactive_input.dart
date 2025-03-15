import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting the current date
import '../models/journal_entry.dart';
import '../services/openai_service.dart';

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
  double _energyLevel = 70; // Default energy level
  String _selectedPhase = 'Follicular';
  int _sleepQualityIndex = 2; // Default sleep quality (Fair)
  bool _isPhysicalActive = false;
  bool _isEmotionalActive = true;
  bool _isLifestyleActive = false;
  String _exercise = '';
  String _emotion = '';
  String _symptoms = '';
  String _nutrition = '';
  String _notes = '';

  // Controllers for text fields
  late final TextEditingController _exerciseController;
  late final TextEditingController _emotionController;
  late final TextEditingController _symptomsController;
  late final TextEditingController _nutritionController;
  late final TextEditingController _notesController;

  final List<String> _phases = ['Menstrual', 'Follicular', 'Ovulatory', 'Luteal'];
  final List<String> _sleepQualities = ['Poor', 'Barely Enough', 'Fair', 'Good', 'Rested'];

  final OpenAIService _openAIService = OpenAIService();
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize with data from initial entry if provided
    if (widget.initialEntry != null) {
      _energyLevel = widget.initialEntry!.energyLevel;
      _selectedPhase = widget.initialEntry!.phase;
      _sleepQualityIndex = widget.initialEntry!.sleepQualityIndex;
      _exercise = widget.initialEntry!.exercise;
      _emotion = widget.initialEntry!.emotion;
      _symptoms = widget.initialEntry!.symptoms;
      _nutrition = widget.initialEntry!.nutrition;
      _notes = widget.initialEntry!.notes;
    }

    // Initialize controllers with current values
    _exerciseController = TextEditingController(text: _exercise);
    _emotionController = TextEditingController(text: _emotion);
    _symptomsController = TextEditingController(text: _symptoms);
    _nutritionController = TextEditingController(text: _nutrition);
    _notesController = TextEditingController(text: _notes);
  }

  @override
  void dispose() {
    // Dispose controllers
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
        phase: _selectedPhase,
        energyLevel: _energyLevel,
        sleepQualityIndex: _sleepQualityIndex,
        exercise: _exercise,
        emotion: _emotion,
        symptoms: _symptoms,
        nutrition: _nutrition,
        notes: _notes,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'Daily Check-in',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              formattedDate,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current Phase',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        )
                      ),
                      Text(_selectedPhase,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        )
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Energy Level',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        )
                      ),
                      Text('${_energyLevel.round()}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        )
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Phase selector
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _phases.length,
                  itemBuilder: (context, index) {
                    final phase = _phases[index];
                    final isSelected = phase == _selectedPhase;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(phase),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          if (selected) {
                            setState(() => _selectedPhase = phase);
                          }
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor: Colors.black87,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 40),

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
                          '${_energyLevel.round()}%',
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
                                value: _energyLevel,
                                min: 0,
                                max: 100,
                                onChanged: (value) {
                                  setState(() {
                                    _energyLevel = value;
                                  });
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
                          _sleepQualities[_sleepQualityIndex],
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
                                value: _sleepQualityIndex.toDouble(),
                                min: 0,
                                max: 4,
                                divisions: 4,
                                label: _sleepQualities[_sleepQualityIndex],
                                onChanged: (value) {
                                  setState(() {
                                    _sleepQualityIndex = value.round();
                                  });
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

              // Input Cards
              SizedBox(
                height: 150,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildInputCard('Nutrition', _nutrition, (value) => setState(() => _nutrition = value)),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Additional Input Cards
              SizedBox(
                height: 150,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildInputCard('Exercise', _exercise, (value) => setState(() => _exercise = value)),
                    const SizedBox(width: 16),
                    _buildInputCard('Emotion', _emotion, (value) => setState(() => _emotion = value)),
                    const SizedBox(width: 16),
                    _buildInputCard('Symptoms', _symptoms, (value) => setState(() => _symptoms = value)),
                  ],
                ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryToggle(String label, bool isEnabled, IconData icon) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (label == 'PHYSICAL') _isPhysicalActive = !_isPhysicalActive;
          if (label == 'EMOTIONAL') _isEmotionalActive = !_isEmotionalActive;
          if (label == 'LIFESTYLE') _isLifestyleActive = !_isLifestyleActive;
        });
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isEnabled ? Colors.black87 : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isEnabled ? Colors.white : Colors.grey[600],
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isEnabled ? Colors.black87 : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
      width: 200,
      padding: const EdgeInsets.all(16),
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