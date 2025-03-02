class JournalEntry {
  final PeriodState periodState;
  final Symptoms symptoms;
  final Lifestyle lifestyle;
  final CycleAnalysis cycleAnalysis;
  final Recommendations recommendations;

  JournalEntry({
    required this.periodState,
    required this.symptoms,
    required this.lifestyle,
    required this.cycleAnalysis,
    required this.recommendations,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    print('Received JSON: $json'); // Debug log
    
    final parsedData = json['parsed_data'];
    if (parsedData == null) {
      print('parsed_data is null'); // Debug log
      throw Exception('Invalid response format: parsed_data is missing');
    }

    try {
      return JournalEntry(
        periodState: PeriodState.fromJson(parsedData['period_state'] ?? {}),
        symptoms: Symptoms.fromJson(parsedData['symptoms'] ?? {}),
        lifestyle: Lifestyle.fromJson(parsedData['lifestyle'] ?? {}),
        cycleAnalysis: CycleAnalysis.fromJson(json['cycle_analysis'] ?? {}),
        recommendations: Recommendations.fromJson(json['recommendations'] ?? {}),
      );
    } catch (e, stackTrace) {
      print('Error parsing JSON: $e'); // Debug log
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}

class PeriodState {
  final bool isActive;
  final String flow;
  final bool spotting;

  PeriodState({
    required this.isActive,
    required this.flow,
    required this.spotting,
  });

  factory PeriodState.fromJson(Map<String, dynamic> json) => PeriodState(
    isActive: json['is_active'] ?? false,
    flow: json['flow'] ?? 'none',
    spotting: json['spotting'] ?? false,
  );
}

class Symptoms {
  final List<String> physical;
  final List<String> emotional;

  Symptoms({
    required this.physical,
    required this.emotional,
  });

  factory Symptoms.fromJson(Map<String, dynamic> json) => Symptoms(
    physical: List<String>.from(json['physical'] ?? []),
    emotional: List<String>.from(json['emotional'] ?? []),
  );
}

class Lifestyle {
  final Sleep sleep;
  final Food food;
  final Exercise exercise;

  Lifestyle({
    required this.sleep,
    required this.food,
    required this.exercise,
  });

  factory Lifestyle.fromJson(Map<String, dynamic> json) => Lifestyle(
    sleep: Sleep.fromJson(json['sleep']),
    food: Food.fromJson(json['food']),
    exercise: Exercise.fromJson(json['exercise']),
  );
}

class Sleep {
  final bool mentioned;
  final String? quality;
  final int? hours;

  Sleep({
    required this.mentioned,
    this.quality,
    this.hours,
  });

  factory Sleep.fromJson(Map<String, dynamic> json) => Sleep(
    mentioned: json['mentioned'],
    quality: json['quality'],
    hours: json['hours'],
  );
}

class Food {
  final List<String> meals;
  final List<String> cravings;
  final bool hydrationMentioned;

  Food({
    required this.meals,
    required this.cravings,
    required this.hydrationMentioned,
  });

  factory Food.fromJson(Map<String, dynamic> json) => Food(
    meals: List<String>.from(json['meals']),
    cravings: List<String>.from(json['cravings']),
    hydrationMentioned: json['hydration_mentioned'],
  );
}

class Exercise {
  final bool mentioned;
  final List<String> type;
  final int? durationMinutes;

  Exercise({
    required this.mentioned,
    required this.type,
    this.durationMinutes,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    mentioned: json['mentioned'],
    type: List<String>.from(json['type']),
    durationMinutes: json['duration_minutes'],
  );
}

class CycleAnalysis {
  final String currentPhase;
  final int daysSinceLastPeriod;
  final List<String> keywords;
  final String poeticMessage;

  CycleAnalysis({
    required this.currentPhase,
    required this.daysSinceLastPeriod,
    required this.keywords,
    required this.poeticMessage,
  });

  factory CycleAnalysis.fromJson(Map<String, dynamic> json) => CycleAnalysis(
    currentPhase: json['current_phase'],
    daysSinceLastPeriod: json['days_since_last_period'],
    keywords: List<String>.from(json['keywords']),
    poeticMessage: json['poetic_message'],
  );
}

class Recommendations {
  final List<String> exercise;
  final List<String> nutrition;
  final List<String> emotionalWellbeing;
  final List<String> symptomsManagement;

  Recommendations({
    required this.exercise,
    required this.nutrition,
    required this.emotionalWellbeing,
    required this.symptomsManagement,
  });

  factory Recommendations.fromJson(Map<String, dynamic> json) => Recommendations(
    exercise: List<String>.from(json['exercise']),
    nutrition: List<String>.from(json['nutrition']),
    emotionalWellbeing: List<String>.from(json['emotional_wellbeing']),
    symptomsManagement: List<String>.from(json['symptoms_management']),
  );
}

// Add other model classes similarly 