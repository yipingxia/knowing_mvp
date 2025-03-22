class Recommendation {
  final String currentPhase;
  final int daysSinceLastPeriod;
  final List<String> keywords;
  final String poeticMessage;
  final Map<String, List<String>> recommendations;

  Recommendation({
    required this.currentPhase,
    required this.daysSinceLastPeriod,
    required this.keywords,
    required this.poeticMessage,
    required this.recommendations,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    // Handle both nested and flat structures
    final data = json['recommendations'] ?? json;
    
    // Parse recommendations map
    final recommendationsMap = <String, List<String>>{};
    final rawRecommendations = data['recommendations'] as Map<String, dynamic>? ?? {};
    
    rawRecommendations.forEach((key, value) {
      if (value is List) {
        recommendationsMap[key] = value.cast<String>();
      }
    });

    return Recommendation(
      currentPhase: data['current_phase'] as String? ?? 'Unknown',
      daysSinceLastPeriod: data['days_since_last_period'] as int? ?? 0,
      keywords: (data['keywords'] as List<dynamic>?)?.cast<String>() ?? [],
      poeticMessage: data['poetic_message'] as String? ?? '',
      recommendations: recommendationsMap,
    );
  }

  Map<String, dynamic> toJson() => {
    'current_phase': currentPhase,
    'days_since_last_period': daysSinceLastPeriod,
    'keywords': keywords,
    'poetic_message': poeticMessage,
    'recommendations': recommendations,
  };
} 