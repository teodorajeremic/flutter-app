import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'Login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bioirc/Home.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _ime = TextEditingController();
  final _prezime = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _visina = TextEditingController();
  final _tezina = TextEditingController();

  bool _loading = false;

  List<dynamic> _institucije = [];
  dynamic _selectedInstitucija;
  String? _selectedPol;
  DateTime? _selectedDatumRodjenja;

  @override
  void initState() {
    super.initState();
    _fetchInstitucije();
  }

  @override
  void dispose() {
    _ime.dispose();
    _prezime.dispose();
    _email.dispose();
    _password.dispose();
    _visina.dispose();
    _tezina.dispose();
    super.dispose();
  }

  Future<void> _fetchInstitucije() async {
    final url = Uri.parse('https://dev.intelheart.unic.kg.ac.rs:82/api/app/institucije');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _institucije = data;
        });
      } else {
        _showErrorDialog("Greška pri učitavanju institucija: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorDialog("Greška pri učitavanju institucija: $e");
    }
  }

  Future<void> _signup() async {
    final imeText = _ime.text.trim();
    final prezimeText = _prezime.text.trim();
    final emailText = _email.text.trim();
    final passwordText = _password.text.trim();
    final visinaText = _visina.text.trim();
    final tezinaText = _tezina.text.trim();

    if (imeText.isEmpty || prezimeText.isEmpty) {
      _showErrorDialog("Ime i prezime su obavezni");
      return;
    }
    if (emailText.isEmpty) {
      _showErrorDialog("Email je obavezan");
      return;
    }
    if (passwordText.isEmpty) {
      _showErrorDialog("Lozinka je obavezna");
      return;
    }
    if (_selectedInstitucija == null) {
      _showErrorDialog("Molimo izaberite instituciju");
      return;
    }

    setState(() => _loading = true);

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final deviceId = androidInfo.id;

      final url = Uri.parse('https://dev.intelheart.unic.kg.ac.rs:82/api/app/instalacija');

      // final response = await http.post(url, body: {
      //   'device_id': deviceId,
      //   'institucija': _selectedInstitucija.toString(),
      //   'email': emailText,
      //   'ime': imeText,
      //   'prezime': prezimeText,
      //   'pol': _selectedPol == 'Muški' ? 'm' : _selectedPol == 'Ženski' ? 'z' : '',
      //   'datum_rodjenja': _selectedDatumRodjenja != null
      //       ? "${_selectedDatumRodjenja!.day}.${_selectedDatumRodjenja!.month}.${_selectedDatumRodjenja!.year}"
      //       : '',
      //   'visina': visinaText,
      //   'tezina': tezinaText,
      // });
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'device_id': deviceId,
          'institucija': _selectedInstitucija,
          'email': emailText,
          'ime': imeText,
          'prezime': prezimeText,
          'pol': _selectedPol == 'Muški' ? 'm' : _selectedPol == 'Ženski' ? 'z' : '',
          'datum_rodjenja': _selectedDatumRodjenja != null
              ? "${_selectedDatumRodjenja!.day}.${_selectedDatumRodjenja!.month}.${_selectedDatumRodjenja!.year}"
              : '',
          'visina': visinaText,
          'tezina': tezinaText,
        }),
      );


      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessDialog("Uspešno ste registrovani!");
        print("Response body: ${response.body}");
        try {
          final Map<String, dynamic> body = json.decode(response.body);

          final idPacijenta = body['data'] != null ? body['data']['id'] : null;

          if (idPacijenta != null) {
            // cuvanje id pacijenta u SharedPreferances
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('patient_id', idPacijenta);

            print('Sačuvan patient_id = $idPacijenta');
            // redirekcija na pocetnu stranu
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          } else {
            print('Ne mogu da pronađem id pacijenta u response body');
          }
        } catch (e) {
          print('Greška pri parsiranju response.body: $e');
          _showSuccessDialog("Uspešno ste registrovani! (nije moguće parsirati id)");
        }
      }
    } catch (e) {
      _showErrorDialog("Došlo je do greške: $e");
    } finally {
      setState(() => _loading = false);
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

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDatumRodjenja) {
      setState(() {
        _selectedDatumRodjenja = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 180,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              alignment: Alignment.center,
              child: Image.asset(
                'assets/Logo.png',
                width: 250,
              ),
            ),
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
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
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
                            controller: _ime,
                            decoration: const InputDecoration(
                              hintText: 'Ime',
                              border: InputBorder.none,
                            ),
                          ),
                          const Divider(),
                          TextField(
                            controller: _prezime,
                            decoration: const InputDecoration(
                              hintText: 'Prezime',
                              border: InputBorder.none,
                            ),
                          ),
                          const Divider(),
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
                              hintText: 'Lozinka',
                              border: InputBorder.none,
                            ),
                          ),
                          const Divider(),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _selectedPol,
                            items: ['Muški', 'Ženski']
                                .map((pol) => DropdownMenuItem<String>(
                              value: pol,
                              child: Text(pol),
                            ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedPol = value;
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'Pol',
                              border: InputBorder.none,
                            ),
                          ),
                          const Divider(),
                          GestureDetector(
                            onTap: _pickDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Datum rođenja',
                                border: InputBorder.none,
                              ),
                              child: Text(
                                _selectedDatumRodjenja == null
                                    ? 'Odaberi datum'
                                    : "${_selectedDatumRodjenja!.day}.${_selectedDatumRodjenja!.month}.${_selectedDatumRodjenja!.year}",
                              ),
                            ),
                          ),
                          const Divider(),
                          TextField(
                            controller: _visina,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Visina (cm)',
                              border: InputBorder.none,
                            ),
                          ),
                          const Divider(),
                          TextField(
                            controller: _tezina,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Težina (kg)',
                              border: InputBorder.none,
                            ),
                          ),
                          const Divider(),
                          DropdownButtonFormField<dynamic>(
                            isExpanded: true,
                            value: _selectedInstitucija,
                            items: _institucije.map((item) {
                              return DropdownMenuItem<dynamic>(
                                value: item['id'],
                                child: Text(
                                  item['naziv'],
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedInstitucija = value;
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'Institucija',
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
                        onPressed: _loading ? null : _signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF474B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Sign Up', style: TextStyle(fontSize: 16)),
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
    );
  }
}
