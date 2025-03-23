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
    // Parse recommendations map
    final Map<String, List<String>> recommendationsMap = {};
    final rawRecommendations = data['recommendations'] as Map<String, dynamic>? ?? {};
    
    rawRecommendations.forEach((key, value) {
      if (value is List) {
        recommendationsMap[key] = value.cast<String>();
      }
    });

    // Parse date from either Timestamp or String
    DateTime parsedDate;
    if (data['date'] is Timestamp) {
      parsedDate = (data['date'] as Timestamp).toDate();
    } else if (data['date'] is String) {
      parsedDate = DateTime.parse(data['date']);
    } else {
      parsedDate = DateTime.now();
    }

    return Recommendation(
      date: parsedDate,
      currentPhase: data['current_phase'] as String? ?? 'Unknown',
      daysSinceLastPeriod: data['days_since_last_period'] as int? ?? 0,
      keywords: (data['keywords'] as List<dynamic>?)?.cast<String>() ?? [],
      poeticMessage: data['poetic_message'] as String? ?? '',
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