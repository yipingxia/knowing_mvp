import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/journal_entry.dart';
import '../services/daily_log_service.dart';
import 'interactive_input.dart';
import '../services/user_info_service.dart';
import '../models/user_info.dart';
import '../theme/app_theme.dart';

class JournalEntriesListScreen extends StatefulWidget {
  const JournalEntriesListScreen({super.key});

  @override
  State<JournalEntriesListScreen> createState() => _JournalEntriesListScreenState();
}

class _JournalEntriesListScreenState extends State<JournalEntriesListScreen> {
  late final DailyLogService _dailyLogService;
  final UserInfoService _userInfoService = UserInfoService(FirebaseFirestore.instance);
  UserInfo? _userInfo;
  
  @override
  void initState() {
    super.initState();
    _dailyLogService = DailyLogService(FirebaseFirestore.instance);
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final userInfo = await _userInfoService.getUserInfo();
      if (mounted) {
        setState(() {
          _userInfo = userInfo;
        });
      }
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  Future<void> _addOrUpdateEntry(DateTime selectedDate, [JournalEntry? initialEntry]) async {
    // If we're adding a new entry for today and no initial entry is provided,
    // try to fetch today's entry first
    JournalEntry? todayEntry;
    if (initialEntry == null && selectedDate.year == DateTime.now().year &&
        selectedDate.month == DateTime.now().month &&
        selectedDate.day == DateTime.now().day) {
      try {
        todayEntry = await _dailyLogService.getTodayLog();
      } catch (e) {
        print('Error fetching today\'s entry: $e');
      }
    }

    final result = await Navigator.push<JournalEntry>(
      context,
      MaterialPageRoute(
        builder: (context) => InteractiveInputScreen(
          selectedDate: selectedDate,
          initialEntry: initialEntry ?? todayEntry,
        ),
      ),
    );

    if (result != null) {
      await _dailyLogService.saveLog(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: ConstrainedBox(
          constraints: AppTheme.maxWidthConstraint,
          child: Text(
            'Journal Entries',
            style: AppTheme.appBarTitleStyle,
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppTheme.backgroundGradientColors,
            stops: const [0.0, 0.4, 0.8, 1.0],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: AppTheme.maxWidthConstraint,
            child: StreamBuilder<List<JournalEntry>>(
              stream: _dailyLogService.getAllLogs(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final entries = snapshot.data ?? [];

                if (entries.isEmpty) {
                  return Center(
                    child: Text(
                      'No entries yet. Add your first entry!',
                      style: AppTheme.subtitleStyle,
                    ),
                  );
                }

                return GridView.builder(
                  padding: AppTheme.screenPadding,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: AppTheme.spacingMedium,
                    mainAxisSpacing: AppTheme.spacingMedium,
                  ),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Container(
                      decoration: AppTheme.entryTileDecoration,
                      child: InkWell(
                        onTap: () => _addOrUpdateEntry(entry.date, entry),
                        child: Padding(
                          padding: AppTheme.cardPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDate(entry.date),
                                style: AppTheme.dateStyle,
                              ),
                              if (entry.notes.isNotEmpty) ...[
                                const SizedBox(height: AppTheme.spacingSmall),
                                Text(
                                  entry.notes,
                                  style: AppTheme.cardBodyStyle,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (entry.energyLevel > 0 || entry.sleepQualityIndex > 0 || 
                                  entry.nutrition.isNotEmpty || entry.exercise.isNotEmpty || 
                                  entry.emotion.isNotEmpty || entry.symptoms.isNotEmpty ||
                                  entry.stressors.isNotEmpty) ...[
                                const SizedBox(height: AppTheme.spacingMedium),
                                Wrap(
                                  spacing: AppTheme.spacingSmall,
                                  runSpacing: AppTheme.spacingSmall,
                                  children: [
                                    if (entry.energyLevel > 0)
                                      _buildTag('Energy', '${entry.energyLevel.round()}%', entry: entry),
                                    if (entry.sleepQualityIndex > 0)
                                      _buildTag('Sleep', _getSleepQualityText(entry.sleepQualityIndex), entry: entry),
                                    if (entry.nutrition.isNotEmpty)
                                      _buildTag('Nutrition', entry.nutrition, entry: entry),
                                    if (entry.exercise.isNotEmpty)
                                      _buildTag('Exercise', entry.exercise, entry: entry),
                                    if (entry.emotion.isNotEmpty)
                                      _buildTag('Emotion', entry.emotion, entry: entry),
                                    if (entry.symptoms.isNotEmpty)
                                      _buildTag('Symptoms', entry.symptoms, entry: entry),
                                    if (entry.stressors.isNotEmpty)
                                      _buildTag('Stressors', '${entry.stressors.length} selected', entry: entry),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrUpdateEntry(DateTime.now()),
        backgroundColor: Colors.black87,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd').format(date);
  }

  Widget _buildTag(String label, String value, {JournalEntry? entry}) {
    List<Widget> children = [];

    if (label == 'Nutrition' && entry != null) {
      if (entry.fiberGrams != null || entry.proteinGrams != null) {
        final fiberColor = _getStatusColor(
          currentValue: entry.fiberGrams,
          recommendedValue: _userInfo?.recommendedFiberIntake,
          isExerciseStress: false,
        );
        final proteinColor = _getStatusColor(
          currentValue: entry.proteinGrams,
          recommendedValue: _userInfo?.recommendedProteinIntake,
          isExerciseStress: false,
        );
        
        children = [
          Text(
            '$label: ',
            style: AppTheme.tagLabelStyle,
          ),
          Text(
            'Fiber: ${entry.fiberGrams?.toStringAsFixed(1) ?? '0'}g',
            style: AppTheme.tagValueStyle,
          ),
          _buildStatusIndicator(fiberColor),
          Text(
            ', Protein: ${entry.proteinGrams?.toStringAsFixed(1) ?? '0'}g',
            style: AppTheme.tagValueStyle,
          ),
          _buildStatusIndicator(proteinColor),
        ];
      }
    } else if (label == 'Exercise' && entry?.bodyStressLevel != null) {
      final stressColor = _getStatusColor(
        currentValue: entry!.bodyStressLevel,
        recommendedValue: 6,
        isExerciseStress: true,
      );
      children = [
        Text(
          '$label: ',
          style: AppTheme.tagLabelStyle,
        ),
        Text(
          'Stress: ${entry.bodyStressLevel!.toStringAsFixed(1)}/10',
          style: AppTheme.tagValueStyle,
        ),
        _buildStatusIndicator(stressColor),
      ];
    } else if (label == 'Sleep' && entry != null) {
      final sleepColor = _getSleepQualityColor(entry.sleepQualityIndex);
      children = [
        Text(
          '$label: ',
          style: AppTheme.tagLabelStyle,
        ),
        Text(
          value,
          style: AppTheme.tagValueStyle,
        ),
        _buildStatusIndicator(sleepColor),
      ];
    } else {
      children = [
        Text(
          '$label: ',
          style: AppTheme.tagLabelStyle,
        ),
        Text(
          value,
          style: AppTheme.tagValueStyle,
        ),
      ];
    }

    return Container(
      padding: AppTheme.tagPadding,
      decoration: AppTheme.tagDecoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  String _getSleepQualityText(int index) {
    final qualities = ['Poor', 'Barely', 'Fair', 'Good', 'Great'];
    return qualities[index];
  }

  // Add this helper function
  Color _getStatusColor({
    required double? currentValue,
    required double? recommendedValue,
    required bool isExerciseStress,
  }) {
    if (currentValue == null || recommendedValue == null) return AppTheme.statusRed;
    
    if (isExerciseStress) {
      // For exercise stress, lower is better
      if (currentValue <= 6) return AppTheme.statusBlue;
      if (currentValue <= 8) return AppTheme.statusYellow;
      return AppTheme.statusRed;
    } else {
      // For fiber and protein, higher is better
      final percentage = (currentValue / recommendedValue) * 100;
      if (percentage >= 100) return AppTheme.statusGreen;
      if (percentage >= 80) return AppTheme.statusBlue;
      return AppTheme.statusRed;
    }
  }

  Color _getSleepQualityColor(int index) {
    switch (index) {
      case 0: return AppTheme.statusRed;    // Poor
      case 1: return AppTheme.statusYellow; // Barely
      case 2: return AppTheme.statusBlue;   // Fair
      case 3: return AppTheme.statusGreen;  // Good
      case 4: return AppTheme.statusGreen;  // Great
      default: return AppTheme.statusRed;
    }
  }

  // Add this widget class before _buildTag
  Widget _buildStatusIndicator(Color color) {
    return Text(
      ' ●',
      style: TextStyle(
        color: color,
        fontSize: 14,
      ),
    );
  }
} 