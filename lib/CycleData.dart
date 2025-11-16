import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

class FilterByDate extends StatefulWidget {
  const FilterByDate({super.key});

  @override
  State<FilterByDate> createState() => _FilterByDateState();
}

class CycleData {
  final String start;
  final String end;
  final Map<String, dynamic> values;

  CycleData({
    required this.start,
    required this.end,
    required this.values,
  });
}

class _FilterByDateState extends State<FilterByDate> {
  bool loading = true;
  List<CycleData> cycles = [];

  @override
  void initState() {
    super.initState();
    _loadFromBackend();
  }

  Future<void> _loadFromBackend() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final patientId = prefs.getString('patientId') ?? '1';

      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final deviceId = androidInfo.id;

      final url = Uri.parse("https://dev.intelheart.unic.kg.ac.rs:82/api/app/data/all");

      final res = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "pacijent": patientId,
          "device": deviceId,
        },
      );

      print("Status: ${res.statusCode}");
      print("Body: ${res.body}");

      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception("Server returned bad status");
      }

      final List<dynamic> jsonList = jsonDecode(res.body);

      List<CycleData> loaded = [];

      for (var item in jsonList) {
        loaded.add(
          CycleData(
            start: item["cycle_start_time"].toString(),
            end: item["cycle_end_time"].toString(),
            values: item, // celu mapu čuvamo kao values
          ),
        );
      }

      setState(() {
        cycles = loaded;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      _showError("Error: $e");
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(msg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Cycles"),
        backgroundColor: const Color(0xFFEF474B),
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : cycles.isEmpty
          ? const Center(child: Text("No cycles returned."))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: cycles.length,
        itemBuilder: (context, index) {
          final c = cycles[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------- START - END ----------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      c.start,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Icon(Icons.arrow_forward),
                    Text(
                      c.end,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ---------- SVI PARAMETRI ----------
                ...c.values.entries.map((entry) {
                  final key = entry.key;
                  final value = entry.value;

                  if (key == "cycle_start_time" ||
                      key == "cycle_end_time") return Container();

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      "$key: $value",
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}
