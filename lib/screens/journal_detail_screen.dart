import 'package:flutter/material.dart';
import '../models/journal_entry.dart';

class JournalDetailScreen extends StatelessWidget {
  final JournalEntry entry;

  const JournalDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Period State', [
              'Active: ${entry.periodState.isActive}',
              'Flow: ${entry.periodState.flow}',
              'Spotting: ${entry.periodState.spotting}',
            ]),
            _buildSection('Symptoms', [
              'Physical: ${entry.symptoms.physical.join(", ")}',
              'Emotional: ${entry.symptoms.emotional.join(", ")}',
            ]),
            _buildSection('Lifestyle', [
              'Sleep: ${entry.lifestyle.sleep.hours} hours',
              'Sleep Quality: ${entry.lifestyle.sleep.quality}',
              'Food: ${entry.lifestyle.food.meals.join(", ")}',
              'Exercise: ${entry.lifestyle.exercise.type.join(", ")}',
            ]),
            _buildSection('Cycle Analysis', [
              'Phase: ${entry.cycleAnalysis.currentPhase}',
              'Days Since Last Period: ${entry.cycleAnalysis.daysSinceLastPeriod}',
              'Message: ${entry.cycleAnalysis.poeticMessage}',
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(item),
            )),
          ],
        ),
      ),
    );
  }
} 