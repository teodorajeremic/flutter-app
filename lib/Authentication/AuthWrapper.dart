import 'package:flutter/material.dart';
import 'package:bioirc/Home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bioirc/Authentication/SignUpProba.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _hasPatientId = false;

  @override
  void initState() {
    super.initState();
    _checkPatientId();
  }

  Future<void> _checkPatientId() async {
    final prefs = await SharedPreferences.getInstance();
    final idPacijenta = prefs.getInt('patient_id');

    setState(() {
      _hasPatientId = idPacijenta != null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Ako postoji ID pacijenta → ide na Home
    if (_hasPatientId) {
      return const HomeScreen();
    }

    // Ako ne postoji → ide na Signup
    return const SignupScreen();
  }
}

