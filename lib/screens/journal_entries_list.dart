import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/journal_entry.dart';
import '../services/daily_log_service.dart';
import 'interactive_input.dart';
import '../services/user_info_service.dart';
import '../models/user_info.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Journal Entries',
          style: GoogleFonts.unna(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<JournalEntry>>(
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
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth > 600;
              return GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWideScreen ? 2 : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWideScreen ? 0.85 : 0.7,
                ),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return _buildEntryTile(context, entry);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrUpdateEntry(DateTime.now()),
        backgroundColor: Colors.black87,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEntryTile(BuildContext context, JournalEntry entry) {
    return InkWell(
      onTap: () => _addOrUpdateEntry(entry.date, entry),
      child: Container(
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
              DateFormat.MMMd().format(entry.date),
              style: GoogleFonts.unna(
                fontSize: 20,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              entry.phase,
              style: GoogleFonts.unna(
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatItem('Energy', '${entry.energyLevel.round()}%'),
                const SizedBox(width: 16),
                _buildStatItem('Sleep', _getSleepQualityText(entry.sleepQualityIndex)),
              ],
            ),
            if (entry.nutrition.isNotEmpty || entry.exercise.isNotEmpty || 
                entry.emotion.isNotEmpty || entry.symptoms.isNotEmpty ||
                entry.stressors.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (entry.nutrition.isNotEmpty)
                    _buildTag('Nutrition', entry.nutrition, entry: entry),
                  if (entry.exercise.isNotEmpty)
                    _buildTag('Exercise', entry.exercise, entry: entry),
                  if (entry.emotion.isNotEmpty)
                    _buildTag('Emotion', entry.emotion),
                  if (entry.symptoms.isNotEmpty)
                    _buildTag('Symptoms', entry.symptoms),
                  if (entry.stressors.isNotEmpty)
                    _buildTag('Stressors', '${entry.stressors.length} selected'),
                ],
              ),
            ],
            if (entry.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                entry.notes,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  String _getSleepQualityText(int index) {
    final qualities = ['Poor', 'Barely', 'Fair', 'Good', 'Great'];
    return qualities[index];
  }

  // Add these color constants at the top of the class
  static const Color statusBlue = Color(0xFF2196F3);
  static const Color statusGreen = Color(0xFF4CAF50);
  static const Color statusRed = Color(0xFFF44336);
  static const Color statusYellow = Color(0xFFFFC107);

  // Add this helper function
  Color _getStatusColor({
    required double? currentValue,
    required double? recommendedValue,
    required bool isExerciseStress,
  }) {
    if (currentValue == null || recommendedValue == null) return statusRed;
    
    if (isExerciseStress) {
      // For exercise stress, lower is better
      if (currentValue <= 6) return statusBlue;
      if (currentValue <= 8) return statusYellow;
      return statusRed;
    } else {
      // For fiber and protein, higher is better
      final percentage = (currentValue / recommendedValue) * 100;
      if (percentage >= 100) return statusGreen;
      if (percentage >= 80) return statusBlue;
      return statusRed;
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

  Widget _buildTag(String label, String value, {JournalEntry? entry}) {
    // For nutrition tag, show fiber and protein content
    String displayValue = value;
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
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            'Fiber: ${entry.fiberGrams?.toStringAsFixed(1) ?? '0'}g',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.grey[800],
            ),
          ),
          _buildStatusIndicator(fiberColor),
          Text(
            ', Protein: ${entry.proteinGrams?.toStringAsFixed(1) ?? '0'}g',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.grey[800],
            ),
          ),
          _buildStatusIndicator(proteinColor),
        ];
      }
    } else if (label == 'Exercise' && entry?.bodyStressLevel != null) {
      final stressColor = _getStatusColor(
        currentValue: entry!.bodyStressLevel,
        recommendedValue: 6, // Using 6 as the threshold for moderate stress
        isExerciseStress: true,
      );
      children = [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          '$value (Stress: ${entry.bodyStressLevel!.toStringAsFixed(1)}/10)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.grey[800],
          ),
        ),
        _buildStatusIndicator(stressColor),
      ];
    } else {
      children = [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.grey[800],
          ),
        ),
      ];
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
} 