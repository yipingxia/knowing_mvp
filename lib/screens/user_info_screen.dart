import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_info.dart';
import '../services/user_info_service.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final UserInfoService _userInfoService = UserInfoService(FirebaseFirestore.instance);
  UserInfo? _userInfo;
  bool _isLoading = true;
  bool _isEditing = false;
  Gender _selectedGender = Gender.female;
  int _height = 165; // Default height
  int _weight = 60; // Default weight
  DateTime _birthDate = DateTime.now().subtract(const Duration(days: 365 * 25)); // Default age 25
  ActivityLevel _activityLevel = ActivityLevel.sedentary;
  
  // Color scheme
  static const Color primaryColor = Color(0xFF2C2C2C);
  static const Color secondaryColor = Color(0xFF4A4A4A);
  static const Color surfaceColor = Color(0xFFF5F5F5);
  static const Color borderColor = Color(0xFFE0E0E0);
  
  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final userInfo = await _userInfoService.getUserInfo();
      if (userInfo != null && mounted) {
        setState(() {
          _userInfo = userInfo;
          _selectedGender = userInfo.gender;
          _height = userInfo.height;
          _weight = userInfo.weight;
          _birthDate = userInfo.birthDate;
          _activityLevel = userInfo.activityLevel;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading user info: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user info: $e')),
        );
      }
    }
  }

  Future<void> _saveUserInfo() async {
    try {
      setState(() => _isLoading = true);

      final userInfo = UserInfo.create(
        gender: _selectedGender,
        height: _height,
        weight: _weight,
        birthDate: _birthDate,
        activityLevel: _activityLevel,
      );

      await _userInfoService.saveUserInfo(userInfo);
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildSliderSection({
    required String title,
    required int value,
    required int min,
    required int max,
    required String unit,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: GoogleFonts.unna(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value$unit',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: primaryColor,
                inactiveTrackColor: surfaceColor,
                thumbColor: primaryColor,
                overlayColor: primaryColor.withOpacity(0.1),
                trackHeight: 8.0,
              ),
              child: Slider(
                value: value.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: max - min,
                onChanged: (value) => onChanged(value.round()),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getActivityLevelText(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.light:
        return '1-2 times/week';
      case ActivityLevel.moderate:
        return '2-3 times/week';
      case ActivityLevel.active:
        return '3-5 times/week';
      case ActivityLevel.veryActive:
        return '6-7 times/week';
      case ActivityLevel.professional:
        return 'Professional Athlete';
    }
  }

  Widget _buildActivityLevelSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Activity Level',
              style: GoogleFonts.unna(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: primaryColor,
              ),
            ),
            Text(
              _getActivityLevelText(_activityLevel),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          child: Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    // Background bars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        ActivityLevel.values.length,
                        (index) => Container(
                          width: 8,
                          height: 40 + (index * 20),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    // Active bars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        ActivityLevel.values.length,
                        (index) => Container(
                          width: 8,
                          height: 40 + (index * 20),
                          decoration: BoxDecoration(
                            color: index <= _activityLevel.index
                                ? primaryColor
                                : surfaceColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    // Slider
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.transparent,
                        inactiveTrackColor: Colors.transparent,
                        thumbColor: primaryColor,
                        overlayColor: primaryColor.withOpacity(0.1),
                        trackHeight: 0,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 12,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 24,
                        ),
                      ),
                      child: Slider(
                        value: _activityLevel.index.toDouble(),
                        min: 0,
                        max: ActivityLevel.values.length - 1,
                        divisions: ActivityLevel.values.length - 1,
                        onChanged: (value) {
                          setState(() {
                            _activityLevel = ActivityLevel.values[value.round()];
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: surfaceColor,
              onSurface: primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Center(
          child: ConstrainedBox(
            constraints: AppTheme.maxWidthConstraint,
            child: Text(
              'User Information',
              style: AppTheme.appBarTitleStyle,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppTheme.backgroundGradientColors,
            stops: const [0.0, 0.4, 0.8, 1.0],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: AppTheme.maxWidthConstraint,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: AppTheme.screenPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Profile Information',
                              style: AppTheme.titleStyle,
                            ),
                            TextButton.icon(
                              onPressed: () => setState(() => _isEditing = !_isEditing),
                              icon: Icon(
                                _isEditing ? Icons.save : Icons.edit,
                                color: AppTheme.secondaryColor,
                                size: 20,
                              ),
                              label: Text(
                                _isEditing ? 'Save' : 'Edit',
                                style: AppTheme.tagValueStyle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingMedium),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: AppTheme.spacingMedium,
                          crossAxisSpacing: AppTheme.spacingMedium,
                          childAspectRatio: 1.0,
                          children: [
                            _buildSummaryCard(
                              'Gender',
                              _userInfo?.gender.toString().split('.').last.capitalize() ?? 'Not set',
                              Icons.person,
                            ),
                            _buildSummaryCard(
                              'Height',
                              _userInfo?.height != null ? '${_userInfo!.height} cm' : 'Not set',
                              Icons.height,
                            ),
                            _buildSummaryCard(
                              'Weight',
                              _userInfo?.weight != null ? '${_userInfo!.weight} kg' : 'Not set',
                              Icons.monitor_weight,
                            ),
                            _buildSummaryCard(
                              'Age',
                              _userInfo?.age != null ? '${_userInfo!.age} years' : 'Not set',
                              Icons.cake,
                            ),
                            _buildSummaryCard(
                              'Activity Level',
                              _userInfo?.activityLevel.toString().split('.').last.capitalize() ?? 'Not set',
                              Icons.directions_run,
                            ),
                            _buildSummaryCard(
                              'Daily Intake',
                              _userInfo?.recommendedCalories != null ? '${_userInfo!.recommendedCalories.round()} kcal' : 'Not set',
                              Icons.restaurant,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Container(
      decoration: AppTheme.glassCardDecoration,
      child: Padding(
        padding: AppTheme.glassCardPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppTheme.secondaryColor,
              size: 24,
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              title,
              style: AppTheme.tagLabelStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              value,
              style: AppTheme.tagValueStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
} 