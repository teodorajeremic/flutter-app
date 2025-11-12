import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Login.dart';
import 'Authentication.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _auth = AuthService();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    final nameText = _name.text.trim();
    final emailText = _email.text.trim();
    final passwordText = _password.text.trim();

    if (nameText.isEmpty) {
      _showErrorDialog("Name Is Required");
      return;
    }
    if (emailText.isEmpty) {
      _showErrorDialog("Email Is Required");
      return;
    }
    if (passwordText.isEmpty) {
      _showErrorDialog("Password Is Required");
      return;
    }

    final user = await _auth.createUserWithEmailAndPassword(
      nameText,
      emailText,
      passwordText,
    );

    if (user != null) {
      _showSuccessDialog("Registered Successfully");
    } else {
      _showErrorDialog("Email Is Already Registered");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Icon(Icons.error_outline, color: Colors.red, size: 40),
        content: Text(message, textAlign: TextAlign.center),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 40),
        content: Text(message, textAlign: TextAlign.center),
      ),
    );
  }

  void goToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Orange curved header
            Container(
              width: double.infinity,
              height: 180,
              decoration: const BoxDecoration(
                // gradient: LinearGradient(
                //   colors: [Colors.green, Color(0xFF54b574)],
                //   begin: Alignment.topLeft,
                //   end: Alignment.bottomRight,
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
                    'assets/Logo.png',
                    width: 250,
                  ),

                ],
              ),
            ),
            // Input fields and button
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    Text(
                      'REGISTER',
                      style: GoogleFonts.roboto(
                        fontSize: 30,
                        letterSpacing: 5,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create Your Account',
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // White card with shadow
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
                          // Name Field
                          TextField(
                            controller: _name,
                            decoration: const InputDecoration(
                              hintText: 'Full Name',
                              border: InputBorder.none,
                            ),
                          ),
                          const Divider(),

                          // Email Field
                          TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'Email Address',
                              border: InputBorder.none,
                            ),
                          ),
                          const Divider(),

                          // Password Field
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
                        onPressed: _signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFEF474B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already Have An Account ? "),
                        GestureDetector(
                          onTap: () => goToLogin(context),
                          child: const Text(
                            "Sign In",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
    );
  }
}
