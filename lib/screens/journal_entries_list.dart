import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/journal_entry.dart';
import '../services/daily_log_service.dart';
import 'interactive_input.dart';

class JournalEntriesListScreen extends StatefulWidget {
  const JournalEntriesListScreen({super.key});

  @override
  State<JournalEntriesListScreen> createState() => _JournalEntriesListScreenState();
}

class _JournalEntriesListScreenState extends State<JournalEntriesListScreen> {
  late final DailyLogService _dailyLogService;
  
  @override
  void initState() {
    super.initState();
    _dailyLogService = DailyLogService(FirebaseFirestore.instance);
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
      appBar: AppBar(
        title: const Text(
          'Journal Entries',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
            return const Center(
              child: Text('No entries yet. Add your first entry!'),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _buildEntryTile(context, entry);
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
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              entry.phase,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
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
            if (entry.nutrition.isNotEmpty || entry.exercise.isNotEmpty || entry.emotion.isNotEmpty || entry.symptoms.isNotEmpty) ...[
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
                ],
              ),
            ],
            if (entry.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                entry.notes,
                style: const TextStyle(fontSize: 12),
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
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
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

  Widget _buildTag(String label, String value, {JournalEntry? entry}) {
    // For nutrition tag, show fiber and protein content
    String displayValue = value;
    if (label == 'Nutrition' && entry != null) {
      if (entry.fiberGrams != null || entry.proteinGrams != null) {
        displayValue = 'Fiber: ${entry.fiberGrams?.toStringAsFixed(1) ?? '0'}g, '
                      'Protein: ${entry.proteinGrams?.toStringAsFixed(1) ?? '0'}g';
      }
    }
    // For exercise tag, show body stress level if available
    if (label == 'Exercise' && entry?.bodyStressLevel != null) {
      displayValue = '$value (Stress: ${entry!.bodyStressLevel!.toStringAsFixed(1)}/10)';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            displayValue,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
} 