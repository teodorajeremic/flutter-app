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

  /// -------------------------------
  /// MAPIRANJE BACKEND KLJUČEVA → LABELA
  /// -------------------------------
  final Map<String, String> fieldLabels = {
    "cycle_start_time": "Cycle start time",
    "cycle_end_time": "Cycle end time",
    "resting_heart_rate_bpm": "Resting heart rate (bpm)",
    "heart_rate_variability_ms": "Heart rate variability (ms)",
    "skin_temp_celsius": "Skin temp (celsius)",
    "blood_oxygen": "Blood oxygen %",
    "energy_burned_cal": "Energy burned (cal)",
    "max_hr_bpm": "Max HR (bpm)",
    "average_hr_bpm": "Average HR (bpm)",
    "sleep_onset": "Sleep onset",
    "wake_onset": "Wake onset",
    "respiratory_rate_rpm": "Respiratory rate (rpm)",
    "asleep_duration_min": "Asleep duration (min)",
    "in_bed_duration_min": "In bed duration (min)",
    "light_sleep_duration_min": "Light sleep duration (min)",
    "deep_sws_duration_min": "Deep (SWS) duration (min)",
    "rem_duration_min": "REM duration (min)",
    "awake_duration_min": "Awake duration (min)",
    "sleep_need_min": "Sleep need (min)",
    "sleep_debt_min": "Sleep debt (min)",
  };

  /// -------------------------------
  /// IKONICE PO POLJIMA
  /// -------------------------------
  final Map<String, IconData> fieldIcons = {
    'Cycle start time': Icons.play_arrow,
    'Cycle end time': Icons.stop,
    'Resting heart rate (bpm)': Icons.favorite,
    'Heart rate variability (ms)': Icons.timeline,
    'Skin temp (celsius)': Icons.thermostat,
    'Blood oxygen %': Icons.bloodtype,
    'Energy burned (cal)': Icons.local_fire_department,
    'Max HR (bpm)': Icons.arrow_upward,
    'Average HR (bpm)': Icons.favorite_border,
    'Sleep onset': Icons.nights_stay,
    'Wake onset': Icons.wb_sunny,
    'Respiratory rate (rpm)': Icons.air,
    'Asleep duration (min)': Icons.bedtime,
    'In bed duration (min)': Icons.king_bed,
    'Light sleep duration (min)': Icons.light_mode,
    'Deep (SWS) duration (min)': Icons.dark_mode,
    'REM duration (min)': Icons.visibility,
    'Awake duration (min)': Icons.waves,
    'Sleep need (min)': Icons.access_time,
    'Sleep debt (min)': Icons.warning,
  };

  /// -------------------------------
  /// BOJE PO POLJIMA
  /// -------------------------------
  final Map<String, Color> fieldColors = {
    'Resting heart rate (bpm)': Colors.red,
    'Heart rate variability (ms)': Colors.blue,
    'Skin temp (celsius)': Colors.orange,
    'Blood oxygen %': Colors.cyan,
    'Energy burned (cal)': Colors.deepOrange,
    'Max HR (bpm)': Colors.green,
    'Average HR (bpm)': Colors.lightGreen,
    'Respiratory rate (rpm)': Colors.teal,
    'Asleep duration (min)': Colors.indigo,
    'In bed duration (min)': Colors.blueGrey,
    'Light sleep duration (min)': Colors.yellow,
    'Deep (SWS) duration (min)': Colors.deepPurple,
    'REM duration (min)': Colors.pink,
    'Awake duration (min)': Colors.grey,
    'Sleep need (min)': Colors.brown,
    'Sleep debt (min)': Colors.redAccent,
  };

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
            values: item,
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

  /// -------------------------------------------------
  ///  WIDGET ZA PRIKAZ POLJA
  /// -------------------------------------------------
  Widget _buildFieldBox(String label, dynamic value) {
    final icon = fieldIcons[label];
    final color = fieldColors[label] ?? Colors.grey;

    final textColor = (color is MaterialColor) ? color.shade700 : color;

    return SizedBox(
      height: 90,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "$label: $value",
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// -------------------------------
  ///  UI
  /// -------------------------------
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
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER — START → END
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

                const SizedBox(height: 14),

                /// POLJA U 2 KOLONE
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double itemWidth = (constraints.maxWidth - 12) / 2;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: fieldLabels.entries.map((entry) {
                        final backendKey = entry.key;
                        final label = entry.value;

                        if (!c.values.containsKey(backendKey)) {
                          return const SizedBox.shrink();
                        }

                        final value = c.values[backendKey];

                        return SizedBox(
                          width: itemWidth,
                          child: _buildFieldBox(label, value),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
