import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class GlassCard extends StatelessWidget {
  static const Color primaryColor = Color(0xFF2C2C2C);
  static const Color secondaryColor = Color(0xFF4A4A4A);
  static const Color surfaceColor = Color(0xFFF5F5F5);
  static const Color borderColor = Color(0xFFE0E0E0);

  final String title;
  final List<String> recommendations;
  final double rotationAngle;

  const GlassCard({
    super.key,
    required this.title,
    required this.recommendations,
    this.rotationAngle = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotationAngle,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title at the top with Unna font
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.unna(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(), // Push recommendations to bottom
                  // Recommendations at the bottom with default font
                  ...recommendations.map((recommendation) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: secondaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              recommendation,
                              style: TextStyle(
                                fontSize: 16,
                                color: primaryColor.withOpacity(0.8),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 