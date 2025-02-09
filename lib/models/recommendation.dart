class Recommendation {
  final String currentPhase;
  final int daysSinceLastPeriod;
  final List<String> keywords;
  final Map<String, List<String>> recommendations;

  Recommendation.fromJson(Map<String, dynamic> json)
      : currentPhase = json['current_phase'],
        daysSinceLastPeriod = json['days_since_last_period'],
        keywords = List<String>.from(json['keywords']),
        recommendations = Map<String, List<String>>.from(
          json['recommendations'].map(
            (key, value) => MapEntry(
              key,
              List<String>.from(value),
            ),
          ),
        );
} 