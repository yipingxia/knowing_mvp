import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/user_service.dart';
import 'home_screen.dart';
import '../theme/app_theme.dart';
import '../services/user_info_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_info_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  final _userService = UserService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await _userService.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(username: _usernameController.text),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid credentials')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _register() async {
    if (!_registerFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await _userService.registerUsername(
        _usernameController.text,
        _passwordController.text,
      );

      if (success && mounted) {
        // After successful registration, check if user info exists
        final userInfoService = UserInfoService(FirebaseFirestore.instance);
        final userInfo = await userInfoService.getUserInfo();

        if (userInfo == null && mounted) {
          // If no user info exists, redirect to UserInfoScreen in edit mode
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const UserInfoScreen(forceEdit: true),
            ),
          );
        } else if (mounted) {
          // If user info exists, proceed to home screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(username: _usernameController.text),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration failed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
            constraints: AppTheme.maxFormWidthConstraint,
        child: SingleChildScrollView(
              padding: AppTheme.screenPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                    'Welcome to Knowing',
                    style: AppTheme.titleStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingXLarge),
                  Container(
                    decoration: AppTheme.glassCardDecoration,
                    child: Column(
                      children: [
                        TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'Login'),
                            Tab(text: 'Register'),
                          ],
                          labelColor: AppTheme.secondaryColor,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: AppTheme.secondaryColor,
                          labelStyle: AppTheme.cardTitleStyle,
                          unselectedLabelStyle: AppTheme.cardTitleStyle,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          indicatorSize: TabBarIndicatorSize.label,
                          indicatorWeight: 3,
                          dividerColor: Colors.transparent,
                          splashBorderRadius: BorderRadius.circular(8),
                          overlayColor: MaterialStateProperty.all(
                            AppTheme.secondaryColor.withOpacity(0.1),
                          ),
                        ),
                        SizedBox(
                          height: 400,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Login Tab
                              Form(
                                key: _loginFormKey,
                                child: Padding(
                                  padding: AppTheme.glassCardPadding,
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: _usernameController,
                                        decoration: AppTheme.textFieldDecoration.copyWith(
                                          labelText: 'Username',
                                          labelStyle: AppTheme.poeticMessageStyle,
                                          prefixIcon: const Icon(Icons.person, color: AppTheme.secondaryColor),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your username';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: AppTheme.spacingMedium),
                                      TextFormField(
                                        controller: _passwordController,
                                        decoration: AppTheme.textFieldDecoration.copyWith(
                                          labelText: 'Password',
                                          labelStyle: AppTheme.poeticMessageStyle,
                                          prefixIcon: const Icon(Icons.lock, color: AppTheme.secondaryColor),
                                        ),
                                        obscureText: true,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your password';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: AppTheme.spacingLarge),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: AppTheme.elevatedButtonStyle,
                                          onPressed: _isLoading ? null : _login,
                                          child: _isLoading
                                            ? SizedBox(
                                                height: 24,
                                                width: 24,
                                                child: CircularProgressIndicator(
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              )
                                            : Text(
                                                'Login',
                                                style: AppTheme.cardTitleStyle.copyWith(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Register Tab
                              Form(
                                key: _registerFormKey,
                                child: Padding(
                                  padding: AppTheme.glassCardPadding,
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: _usernameController,
                                        decoration: AppTheme.textFieldDecoration.copyWith(
                                          labelText: 'Username',
                                          labelStyle: AppTheme.poeticMessageStyle,
                                          prefixIcon: const Icon(Icons.person, color: AppTheme.secondaryColor),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter a username';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: AppTheme.spacingMedium),
                                      TextFormField(
                                        controller: _passwordController,
                                        decoration: AppTheme.textFieldDecoration.copyWith(
                                          labelText: 'Password',
                                          labelStyle: AppTheme.poeticMessageStyle,
                                          prefixIcon: const Icon(Icons.lock, color: AppTheme.secondaryColor),
                                        ),
                                        obscureText: true,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter a password';
                                          }
                                          if (value.length < 6) {
                                            return 'Password must be at least 6 characters';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: AppTheme.spacingMedium),
                                      TextFormField(
                                        controller: _confirmPasswordController,
                                        decoration: AppTheme.textFieldDecoration.copyWith(
                                          labelText: 'Confirm Password',
                                          labelStyle: AppTheme.poeticMessageStyle,
                                          prefixIcon: const Icon(Icons.lock, color: AppTheme.secondaryColor),
                                        ),
                                        obscureText: true,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please confirm your password';
                                          }
                                          if (value != _passwordController.text) {
                                            return 'Passwords do not match';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: AppTheme.spacingLarge),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: AppTheme.elevatedButtonStyle,
                                          onPressed: _isLoading ? null : _register,
                                          child: _isLoading
                                            ? SizedBox(
                                                height: 24,
                                                width: 24,
                                                child: CircularProgressIndicator(
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              )
                                            : Text(
                                                'Register',
                                                style: AppTheme.cardTitleStyle.copyWith(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                ),
            ),
          ),
        ),
      ),
    );
  }
} 