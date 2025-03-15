import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/journal_entry.dart';
import 'interactive_input.dart';

class JournalEntriesListScreen extends StatefulWidget {
  const JournalEntriesListScreen({super.key});

  @override
  State<JournalEntriesListScreen> createState() => _JournalEntriesListScreenState();
}

class _JournalEntriesListScreenState extends State<JournalEntriesListScreen> {
  // TODO: Replace with actual data from storage
  List<JournalEntry> entries = [
    JournalEntry(
      date: DateTime.now().subtract(const Duration(days: 1)),
      phase: 'Follicular',
      energyLevel: 75,
      sleepQualityIndex: 3,
    ),
    JournalEntry(
      date: DateTime.now().subtract(const Duration(days: 2)),
      phase: 'Menstrual',
      energyLevel: 60,
      sleepQualityIndex: 2,
    ),
  ];

  Future<void> _addOrUpdateEntry(DateTime selectedDate, [JournalEntry? initialEntry]) async {
    void updateEntry(JournalEntry entry) {
      setState(() {
        // Remove existing entry for the same date if it exists
        entries.removeWhere((e) => 
          e.date.year == entry.date.year && 
          e.date.month == entry.date.month && 
          e.date.day == entry.date.day
        );
        // Add the new entry
        entries.add(entry);
        // Sort entries by date (newest first)
        entries.sort((a, b) => b.date.compareTo(a.date));
      });
    }

    final result = await Navigator.push<JournalEntry>(
      context,
      MaterialPageRoute(
        builder: (context) => InteractiveInputScreen(
          selectedDate: selectedDate,
          initialEntry: initialEntry,
        ),
      ),
    );

    if (result != null) {
      updateEntry(result);
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
      body: GridView.builder(
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