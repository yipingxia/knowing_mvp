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
    return Recommendation(
      currentPhase: json['current_phase'],
      daysSinceLastPeriod: json['days_since_last_period'],
      keywords: List<String>.from(json['keywords']),
      poeticMessage: json['poetic_message'],
      recommendations: Map<String, List<String>>.from(
        json['recommendations'].map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      ),
    );
  }
} 