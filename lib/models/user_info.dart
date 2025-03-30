import 'package:cloud_firestore/cloud_firestore.dart';

enum Gender { female, male, other }

enum ActivityLevel {
  sedentary,
  light,
  moderate,
  active,
  veryActive,
  professional
}

class UserInfo {
  final Gender gender;
  final double height; // in cm
  final double weight; // in kg
  final DateTime birthDate;
  final ActivityLevel activityLevel;
  final DateTime? lastUpdated;
  final double recommendedFiberIntake;
  final double recommendedProteinIntake;

  UserInfo({
    required this.gender,
    required this.height,
    required this.weight,
    required this.birthDate,
    required this.activityLevel,
    required this.recommendedFiberIntake,
    required this.recommendedProteinIntake,
    this.lastUpdated,
  });

  // Factory constructor to create UserInfo with calculated recommendations
  factory UserInfo.create({
    required Gender gender,
    required double height,
    required double weight,
    required DateTime birthDate,
    required ActivityLevel activityLevel,
    DateTime? lastUpdated,
  }) {
    return UserInfo(
      gender: gender,
      height: height,
      weight: weight,
      birthDate: birthDate,
      activityLevel: activityLevel,
      lastUpdated: lastUpdated,
      recommendedFiberIntake: _calculateRecommendedFiber(weight, activityLevel),
      recommendedProteinIntake: _calculateRecommendedProtein(weight, activityLevel),
    );
  }

  // Calculate age based on birthDate
  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // Calculate recommended fiber intake based on activity level and weight
  static double _calculateRecommendedFiber(double weight, ActivityLevel activityLevel) {
    // Base calorie needs per kg of body weight based on activity level
    double caloriesPerKg;
    switch (activityLevel) {
      case ActivityLevel.sedentary:
        caloriesPerKg = 25; // 25 calories per kg for sedentary
        break;
      case ActivityLevel.light:
        caloriesPerKg = 30;
        break;
      case ActivityLevel.moderate:
        caloriesPerKg = 35;
        break;
      case ActivityLevel.active:
        caloriesPerKg = 40;
        break;
      case ActivityLevel.veryActive:
        caloriesPerKg = 45;
        break;
      case ActivityLevel.professional:
        caloriesPerKg = 50;
        break;
    }

    // Calculate total daily calories
    double dailyCalories = weight * caloriesPerKg;

    // Calculate fiber (14g per 1000 calories)
    double fiber = (dailyCalories / 1000) * 14;

    // Set minimum and maximum fiber intake
    const double minFiber = 25.0; // Minimum recommended fiber
    const double maxFiber = 38.0; // Maximum recommended fiber

    // Ensure fiber is within recommended range
    return fiber.clamp(minFiber, maxFiber);
  }

  // Calculate recommended protein intake
  static double _calculateRecommendedProtein(double weight, ActivityLevel activityLevel) {
    double multiplier;
    switch (activityLevel) {
      case ActivityLevel.sedentary:
        multiplier = 0.8;
        break;
      case ActivityLevel.light:
        multiplier = 1.0;
        break;
      case ActivityLevel.moderate:
        multiplier = 1.2;
        break;
      case ActivityLevel.active:
        multiplier = 1.4;
        break;
      case ActivityLevel.veryActive:
        multiplier = 1.6;
        break;
      case ActivityLevel.professional:
        multiplier = 2.0;
        break;
    }
    return weight * multiplier;
  }

  // Create from Map for Firestore
  factory UserInfo.fromMap(Map<String, dynamic> map) {
    final gender = Gender.values.firstWhere(
      (e) => e.toString() == map['gender'],
      orElse: () => Gender.female,
    );
    final birthDate = (map['birthDate'] as Timestamp).toDate();
    final activityLevel = ActivityLevel.values.firstWhere(
      (e) => e.toString() == map['activityLevel'],
      orElse: () => ActivityLevel.sedentary,
    );
    final weight = (map['weight'] as num).toDouble();

    return UserInfo(
      gender: gender,
      height: (map['height'] as num).toDouble(),
      weight: weight,
      birthDate: birthDate,
      activityLevel: activityLevel,
      lastUpdated: map['lastUpdated'] != null 
        ? (map['lastUpdated'] as Timestamp).toDate()
        : null,
      recommendedFiberIntake: _calculateRecommendedFiber(weight, activityLevel),
      recommendedProteinIntake: _calculateRecommendedProtein(weight, activityLevel),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'gender': gender.toString(),
      'height': height,
      'weight': weight,
      'birthDate': Timestamp.fromDate(birthDate),
      'activityLevel': activityLevel.toString(),
      'lastUpdated': Timestamp.fromDate(DateTime.now()),
      'recommendedFiberIntake': recommendedFiberIntake,
      'recommendedProteinIntake': recommendedProteinIntake,
    };
  }

  // Create a copy with some fields updated
  UserInfo copyWith({
    Gender? gender,
    double? height,
    double? weight,
    DateTime? birthDate,
    ActivityLevel? activityLevel,
    DateTime? lastUpdated,
  }) {
    final newGender = gender ?? this.gender;
    final newBirthDate = birthDate ?? this.birthDate;
    final newActivityLevel = activityLevel ?? this.activityLevel;
    final newWeight = weight ?? this.weight;

    return UserInfo(
      gender: newGender,
      height: height ?? this.height,
      weight: newWeight,
      birthDate: newBirthDate,
      activityLevel: newActivityLevel,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      recommendedFiberIntake: _calculateRecommendedFiber(newWeight, newActivityLevel),
      recommendedProteinIntake: _calculateRecommendedProtein(newWeight, newActivityLevel),
    );
  }
} 