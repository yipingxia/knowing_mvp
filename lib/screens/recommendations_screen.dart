import 'package:flutter/material.dart';
import '../models/recommendation.dart';

class RecommendationsScreen extends StatelessWidget {
  final Recommendation recommendation;

  const RecommendationsScreen({
    super.key,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Recommendations'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 600;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Phase - Always full width
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Current Phase',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          recommendation.currentPhase,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // You Logged - Always full width
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'You Logged',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: recommendation.keywords
                              .map((keyword) => Chip(label: Text(keyword)))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Recommendations
                if (isWideScreen)
                  // Grid layout for wide screens
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: recommendation.recommendations.entries.map(
                      (entry) => SizedBox(
                        width: (constraints.maxWidth - 48) / 2, // Account for padding and spacing
                        child: _buildRecommendationCard(entry),
                      ),
                    ).toList(),
                  )
                else
                  // Single column layout for mobile
                  Column(
                    children: recommendation.recommendations.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildRecommendationCard(entry),
                      ),
                    ).toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendationCard(MapEntry<String, List<String>> entry) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Make the card fit its content
          children: [
            Text(
              entry.key.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...entry.value.map(
              (recommendation) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(recommendation)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 