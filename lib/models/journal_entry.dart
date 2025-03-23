class JournalEntry {
  final DateTime date;
  final String phase;
  final double energyLevel;
  final int sleepQualityIndex;
  final String exercise;
  final String emotion;
  final String symptoms;
  final String nutrition;
  final String notes;
  final double? fiberGrams;
  final double? proteinGrams;
  final double? bodyStressLevel;
  final DateTime? lastPeriodDate;
  final List<String> stressors;

  JournalEntry({
    required this.date,
    this.phase = '',
    this.energyLevel = 0,
    this.sleepQualityIndex = 0,
    this.exercise = '',
    this.emotion = '',
    this.symptoms = '',
    this.nutrition = '',
    this.notes = '',
    this.fiberGrams,
    this.proteinGrams,
    this.bodyStressLevel,
    this.lastPeriodDate,
    this.stressors = const [],
  });

  // Create a copy of this JournalEntry with some fields updated
  JournalEntry copyWith({
    DateTime? date,
    String? phase,
    double? energyLevel,
    int? sleepQualityIndex,
    String? exercise,
    String? emotion,
    String? symptoms,
    String? nutrition,
    String? notes,
    double? fiberGrams,
    double? proteinGrams,
    double? bodyStressLevel,
    DateTime? lastPeriodDate,
    List<String>? stressors,
  }) {
    return JournalEntry(
      date: date ?? this.date,
      phase: phase ?? this.phase,
      energyLevel: energyLevel ?? this.energyLevel,
      sleepQualityIndex: sleepQualityIndex ?? this.sleepQualityIndex,
      exercise: exercise ?? this.exercise,
      emotion: emotion ?? this.emotion,
      symptoms: symptoms ?? this.symptoms,
      nutrition: nutrition ?? this.nutrition,
      notes: notes ?? this.notes,
      fiberGrams: fiberGrams ?? this.fiberGrams,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      bodyStressLevel: bodyStressLevel ?? this.bodyStressLevel,
      lastPeriodDate: lastPeriodDate ?? this.lastPeriodDate,
      stressors: stressors ?? this.stressors,
    );
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'phase': phase,
      'energyLevel': energyLevel,
      'sleepQualityIndex': sleepQualityIndex,
      'exercise': exercise,
      'emotion': emotion,
      'symptoms': symptoms,
      'nutrition': nutrition,
      'fiberGrams': fiberGrams,
      'proteinGrams': proteinGrams,
      'bodyStressLevel': bodyStressLevel,
      'notes': notes,
      'lastPeriodDate': lastPeriodDate?.toIso8601String(),
      'stressors': stressors,
    };
  }

  // Create from Map for retrieval
  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      date: DateTime.parse(map['date']),
      phase: map['phase'],
      energyLevel: map['energyLevel'],
      sleepQualityIndex: map['sleepQualityIndex'],
      exercise: map['exercise'] ?? '',
      emotion: map['emotion'] ?? '',
      symptoms: map['symptoms'] ?? '',
      nutrition: map['nutrition'] ?? '',
      notes: map['notes'] ?? '',
      fiberGrams: map['fiberGrams']?.toDouble(),
      proteinGrams: map['proteinGrams']?.toDouble(),
      bodyStressLevel: map['bodyStressLevel']?.toDouble(),
      lastPeriodDate: map['lastPeriodDate'] != null ? DateTime.parse(map['lastPeriodDate']) : null,
      stressors: List<String>.from(map['stressors'] ?? []),
    );
  }
} 