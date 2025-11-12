import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Authentication/Authentication.dart';
import 'Authentication/Login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();

  final _newPasswordController = TextEditingController();
  bool _isChangingPassword = false;
  String? _passwordChangeMessage;

  Future<void> _changePassword() async {
    final user = _auth.currentUser;
    final newPassword = _newPasswordController.text.trim();

    if (user == null) {
      setState(() {
        _passwordChangeMessage = 'No User Is Signed In';
      });
      return;
    }
    if (newPassword.length < 6) {
      setState(() {
        _passwordChangeMessage = 'Password Must Be At Least 6 Characters';
      });
      return;
    }

    setState(() {
      _isChangingPassword = true;
      _passwordChangeMessage = null;
    });

    try {
      await user.updatePassword(newPassword);
      await _authService.signout();

      setState(() {
        _passwordChangeMessage = 'Password Changed Successfully';
      });

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);

    } on FirebaseAuthException catch (e) {
      setState(() {
        _passwordChangeMessage = 'Failed To Change Password: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _passwordChangeMessage = 'Unexpected Error: $e';
      });
    } finally {
      setState(() {
        _isChangingPassword = false;
      });
    }
  }

  Future<void> _signOut() async {
    await _authService.signout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false, // removes all previous screens
    );
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        //backgroundColor: const Color(0xFF54b574),
        backgroundColor: const Color(0xFFEF474B),
        foregroundColor: Colors.white,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.login, color: Colors.white),
            SizedBox(width: 8),
            Text('Profile'),
          ],
        ),
      ),
      body: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          final user = snapshot.data;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (user == null) {
            return const Center(
              child: Text(
                'No User Is Currently Signed In',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final displayName = user.displayName ?? 'No display name';
          final email = user.email ?? 'No email';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    email,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out',  style: TextStyle(
                      fontWeight: FontWeight.bold, // tekst bold
                    ),),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.redAccent,
                      minimumSize: const Size(150, 50),
                      side: const BorderSide( // crveni okvir
                        color: Colors.redAccent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock, color: Colors.redAccent),
                    const SizedBox(width: 5),
                    Text(
                      'Change Password',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        color: Colors.redAccent,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'New Password',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isChangingPassword ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF474B),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 50),
                    ),
                    child: _isChangingPassword
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text('Update'),
                  ),
                ),
                if (_passwordChangeMessage != null) ...[
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      _passwordChangeMessage!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: _passwordChangeMessage!.startsWith('Failed') ||
                            _passwordChangeMessage!.startsWith('Unexpected')
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ),
                ],
                              ],
            ),
          );
        },
      ),
    );
  }
}
