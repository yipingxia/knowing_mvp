import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userService = UserService();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isNewUser = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _checkStoredUsername();
  }

  Future<void> _checkStoredUsername() async {
    final storedUsername = _userService.getUsernameFromStorage();
    if (storedUsername != null) {
      final userData = await _userService.getUserData(storedUsername);
      if (userData != null) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomeScreen(username: storedUsername),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleLoginOrRegister() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    
    if (username.isEmpty) {
      setState(() => _errorMessage = 'Please enter a username');
      return;
    }
    
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter a password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool success;
      if (_isNewUser) {
        // Try to register new user
        success = await _userService.registerUsername(username, password);
        if (!success) {
          setState(() => _errorMessage = 'Username already taken');
          setState(() => _isLoading = false);
          return;
        }
      } else {
        // Try to verify existing user
        success = await _userService.verifyUser(username, password);
        if (!success) {
          setState(() => _errorMessage = 'Invalid username or password');
          setState(() => _isLoading = false);
          return;
        }
      }

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(username: username),
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'An error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Knowing'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: const OutlineInputBorder(),
                    errorText: _errorMessage,
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _isNewUser,
                      onChanged: (bool? value) {
                        setState(() {
                          _isNewUser = value ?? false;
                        });
                      },
                    ),
                    const Text('I am a new user'),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLoginOrRegister,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(_isNewUser ? 'Register' : 'Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
} 