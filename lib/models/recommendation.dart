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
      currentPhase: json['current_phase'] as String? ?? 'Unknown',
      daysSinceLastPeriod: json['days_since_last_period'] as int? ?? 0,
      keywords: List<String>.from(json['keywords'] ?? []),
      poeticMessage: json['poetic_message'] as String? ?? 'No message available',
      recommendations: Map<String, List<String>>.from(
        (json['recommendations'] ?? {}).map(
          (key, value) => MapEntry(
            key as String,
            List<String>.from(value ?? []),
          ),
        ),
      ),
    );
  }
} 