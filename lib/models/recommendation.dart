import 'package:cloud_firestore/cloud_firestore.dart';

class Recommendation {
  final DateTime date;
  final String currentPhase;
  final int daysSinceLastPeriod;
  final List<String> keywords;
  final String poeticMessage;
  final Map<String, List<String>> recommendations;

  Recommendation({
    required this.date,
    required this.currentPhase,
    required this.daysSinceLastPeriod,
    required this.keywords,
    required this.poeticMessage,
    required this.recommendations,
  });

  factory Recommendation.fromMap(Map<String, dynamic> data) {
    // Handle both nested and flat structures
    final recommendationsData = data['recommendations'] ?? data;
    
    // Parse recommendations map
    final recommendationsMap = <String, List<String>>{};
    final rawRecommendations = recommendationsData['recommendations'] as Map<String, dynamic>? ?? {};
    
    rawRecommendations.forEach((key, value) {
      if (value is List) {
        recommendationsMap[key] = value.cast<String>();
      }
    });

    return Recommendation(
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      currentPhase: recommendationsData['current_phase'] as String? ?? 'Unknown',
      daysSinceLastPeriod: recommendationsData['days_since_last_period'] as int? ?? 0,
      keywords: (recommendationsData['keywords'] as List<dynamic>?)?.cast<String>() ?? [],
      poeticMessage: recommendationsData['poetic_message'] as String? ?? '',
      recommendations: recommendationsMap,
    );
  }

  Map<String, dynamic> toMap() => {
    'date': Timestamp.fromDate(date),
    'current_phase': currentPhase,
    'days_since_last_period': daysSinceLastPeriod,
    'keywords': keywords,
    'poetic_message': poeticMessage,
    'recommendations': recommendations,
  };
} 