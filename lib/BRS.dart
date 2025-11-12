import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

class BRSPage extends StatefulWidget {
  const BRSPage({super.key});

  @override
  State<BRSPage> createState() => _BRSPageState();
}

class _BRSPageState extends State<BRSPage> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;

  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _responseOptions = [];
  final Map<int, int> _answers = {};

  @override
  void initState() {
    super.initState();
    _fetchQuestionsAndAnswers();
  }

  Future<void> _fetchQuestionsAndAnswers() async {
    try {
      final response = await http.get(
        Uri.parse('https://dev.intelheart.unic.kg.ac.rs:82/api/app/upitnik/brs'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final pitanja = data['pitanja'] as List<dynamic>;
        final odgovori = data['odgovori'] as List<dynamic>;

        setState(() {
          _questions = pitanja
              .map((q) => {"id": q["id"], "pitanje": q["pitanje"]})
              .toList();

          _responseOptions = odgovori
              .map((o) => {"odgovor": o["odgovor"], "vrednost": o["vrednost"]})
              .toList();

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

      final deviceInfo = DeviceInfoPlugin();
      String deviceId = '';
      if (Theme.of(context).platform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id ?? '';
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
      }

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
        "tip": "brs",
        "pitanja": pitanjaMap,
      });

      final response = await http.post(
        Uri.parse('https://dev.intelheart.unic.kg.ac.rs:82/api/app/upitnik'),
        headers: headers,
        body: body,
      );

      print("=== Slanje POST zahteva ===");
      print("URL: https://dev.intelheart.unic.kg.ac.rs:82/api/app/upitnik");
      print("HEADERS: $headers");
      print("BODY: $body");
      print("============================");

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

  /// LEGEND
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
            const Text(
              "Koristite sledeću skalu i za svaku tvrdnju zaokružite broj "
                  "koji najbolje izražava stepen sa kojim se slažete ili ne slažete sa tvrdnjom:",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            ..._responseOptions.map((o) => Text(
              "${o["vrednost"]} = ${o["odgovor"]}",
              style: const TextStyle(fontSize: 14),
            )),
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
                final int value = option["vrednost"];
                return ChoiceChip(
                  label: Text(value.toString()),
                  selected: _answers[id] == value,
                  selectedColor: Colors.indigoAccent,
                  labelStyle: TextStyle(
                    color: _answers[id] == value ? Colors.white : Colors.black,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _answers[id] = value;
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
        title: const Text('BRS Upitnik'),
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
                  'Brief Resilience Scale (BRS)',
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
