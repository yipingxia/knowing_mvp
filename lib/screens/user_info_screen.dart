import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_info.dart';
import '../services/user_info_service.dart';
import 'package:intl/intl.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  late final UserInfoService _userInfoService;
  bool _isLoading = true;
  Gender _selectedGender = Gender.female;
  double _height = 165; // Default height
  double _weight = 60; // Default weight
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
    _userInfoService = UserInfoService(FirebaseFirestore.instance);
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final userInfo = await _userInfoService.getUserInfo();
      if (userInfo != null && mounted) {
        setState(() {
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
        // Navigate back to home screen
        Navigator.pop(context);
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
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
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
          '${value.round()}$unit',
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
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Profile Information',
          style: GoogleFonts.unna(
            color: primaryColor,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: primaryColor),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gender Selection
                Text(
                  'Gender',
                  style: GoogleFonts.unna(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: SegmentedButton<Gender>(
                      segments: const [
                        ButtonSegment(
                          value: Gender.female,
                          label: Text('Female'),
                        ),
                        ButtonSegment(
                          value: Gender.male,
                          label: Text('Male'),
                        ),
                        ButtonSegment(
                          value: Gender.other,
                          label: Text('Other'),
                        ),
                      ],
                      selected: {_selectedGender},
                      onSelectionChanged: (Set<Gender> selection) {
                        setState(() => _selectedGender = selection.first);
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.selected)) {
                              return primaryColor;
                            }
                            return Colors.transparent;
                          },
                        ),
                        foregroundColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.selected)) {
                              return Colors.white;
                            }
                            return primaryColor;
                          },
                        ),
                        padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(vertical: 12),
                        ),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Height and Weight Sliders in the same row
                Row(
                  children: [
                    Expanded(
                      child: _buildSliderSection(
                        title: 'Height',
                        value: _height,
                        min: 110,
                        max: 200,
                        unit: 'cm',
                        onChanged: (value) => setState(() => _height = value),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSliderSection(
                        title: 'Weight',
                        value: _weight,
                        min: 40,
                        max: 180,
                        unit: 'kg',
                        onChanged: (value) => setState(() => _weight = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Activity Level
                _buildActivityLevelSlider(),
                const SizedBox(height: 24),

                // Birth Date
                Text(
                  'Birth Date',
                  style: GoogleFonts.unna(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMMM d, yyyy').format(_birthDate),
                          style: const TextStyle(
                            fontSize: 16,
                            color: primaryColor,
                          ),
                        ),
                        const Icon(
                          Icons.calendar_today,
                          color: secondaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveUserInfo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Save',
                      style: GoogleFonts.unna(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
} 