import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:bioirc/Authentication/Authentication.dart';
// ovo sam izmenila
import 'package:bioirc/Authentication/SignUpProba.dart';
import 'package:bioirc/Home.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _email.text.trim();
    final password = _password.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog(
        email.isEmpty ? "Email Is Required" : "Password Is Required",
      );
      return;
    }

    final user = await _auth.loginUserWithEmailAndPassword(email, password);

    if (user != null) {
      log("User Logged In Successfully");
      _goToHome();
    } else {
      _showErrorDialog("Email or Password Is Incorrect");
    }
  }

  void _goToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false, // remove all previous routes (login, splash, etc.)
    );
  }

  void _goToSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignupScreen()),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Center(
          child: Icon(Icons.error_outline, size: 40, color: Colors.red),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Top curved orange header
            Container(
              width: double.infinity,
              height: 180,
              decoration: const BoxDecoration(
                //gradient: LinearGradient(
                //  colors: [Colors.green, Color(0xFF54b574)],
                //  begin: Alignment.topLeft,
                //  end: Alignment.bottomRight,
                // ),
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    //'assets/Logo.png',
                    'assets/Logo.png',
                    width: 250,
                  ),

                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    Text(
                      'LOG IN',
                      style: GoogleFonts.roboto(
                        letterSpacing: 5,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Welcome Back',
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // White card-like container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'Email',
                              border: InputBorder.none,
                            ),
                          ),
                          const Divider(),

                          TextField(
                            controller: _password,
                            obscureText: true,
                            decoration: const InputDecoration(
                              hintText: 'Password',
                              border: InputBorder.none,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFEF474B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Proceed',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't Have An Account ? ",
                          style: TextStyle(fontSize: 15),
                        ),
                        GestureDetector(
                          onTap: _goToSignup,
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
