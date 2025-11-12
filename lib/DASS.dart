import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DASSPage extends StatefulWidget {
  const DASSPage({super.key});

  @override
  State<DASSPage> createState() => _DASSPageState();
}

class _DASSPageState extends State<DASSPage> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;

  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _responseOptions = [];
  final Map<int, int> _answers = {}; // backend vrednosti 6–9

  @override
  void initState() {
    super.initState();
    _fetchQuestionsAndAnswers();
  }

  Future<void> _fetchQuestionsAndAnswers() async {
    try {
      final response = await http.get(
        Uri.parse('https://dev.intelheart.unic.kg.ac.rs:82/api/app/upitnik/dass'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        setState(() {
          _questions = List<Map<String, dynamic>>.from(data["pitanja"]);
          _responseOptions = List<Map<String, dynamic>>.from(data["odgovori"]);

          // Automatski selektuj prvi odgovor (vrednost 6) za svako pitanje
          for (var q in _questions) {
            _answers[q["id"]] = _responseOptions.first["vrednost"];
          }

          _isLoading = false;
        });
      } else {
        throw Exception("Greška pri preuzimanju podataka sa servera.");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog("Greška pri učitavanju podataka: $e");
    }
  }

  Future<void> _submitAnswers() async {
    if (_answers.length < _questions.length) {
      _showErrorDialog('Molimo odgovorite na sva pitanja.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final patientId = prefs.getInt('patient_id');

      if (patientId == null) {
        _showErrorDialog('Greška: ID pacijenta nije pronađen.');
        setState(() => _isSaving = false);
        return;
      }

      // Uzmi device ID
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = '';
      if (Theme.of(context).platform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id ?? '';
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
      }

      // Formiraj mapu pitanja[id_pitanja] = id_odgovora
      final Map<String, int> pitanjaMap = {};
      _answers.forEach((key, value) {
        pitanjaMap[key.toString()] = value;
      });

      final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "pacijent_id": "1",
        "device_id": deviceId,
      };
      final body = jsonEncode({
        "pacijent": 1,
        "tip": "dass",
        "pitanja": pitanjaMap,
      });

      print("=== Slanje POST zahteva ===");
      print("URL: https://dev.intelheart.unic.kg.ac.rs:82/api/app/upitnik");
      print("HEADERS: $headers");
      print("BODY: $body");
      print("============================");

      final response = await http.post(
        Uri.parse('https://dev.intelheart.unic.kg.ac.rs:82/api/app/upitnik'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessDialog("Odgovori su uspešno sačuvani");
      } else {
        _showErrorDialog("Greška: ${response.body}");
      }
    } catch (e) {
      _showErrorDialog("Došlo je do greške: $e");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // --- Dijalozi ---
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uspeh'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Greška'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Legenda
  Widget _buildLegend() {
    return Card(
      elevation: 2,
      color: Colors.white70,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              "Pročitajte svaku od sledećih tvrdnji i zaokružite broj koji najbolje opisuje kako ste "
                  "se osećali u poslednje dve nedelje.",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            ..._responseOptions.map((o) {
              final displayValue = o["vrednost"] - 6; // prikaz 0–3
              return Text(
                "$displayValue = ${o["odgovor"]}",
                style: const TextStyle(fontSize: 14),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion(Map<String, dynamic> question, int index) {
    final id = question["id"];
    final pitanje = question["pitanje"];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$index. $pitanje",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: _responseOptions.map((option) {
                final int backendValue = option["vrednost"]; // 6–9
                final int displayValue = backendValue - 6; // 0–3
                return ChoiceChip(
                  label: Text(displayValue.toString()),
                  selected: _answers[id] == backendValue,
                  selectedColor: Colors.indigoAccent,
                  labelStyle: TextStyle(
                    color: _answers[id] == backendValue ? Colors.white : Colors.black,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _answers[id] = backendValue; // backend vrednost
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('DASS Upitnik'),
        backgroundColor: const Color(0xFFEF474B),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text(
                  'Depression Anxiety Stress Scale (DASS)',
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    color: Colors.indigo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildLegend(),
                ..._questions.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final question = entry.value;
                  return _buildQuestion(question, index);
                }).toList(),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSaving ? null : _submitAnswers,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    _isSaving ? Colors.grey : const Color(0xFFFF8886),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 14),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Pošalji odgovore',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
