import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:intl/intl.dart';

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

  DateTime? filterStartDate;
  DateTime? filterEndDate;

  final DateFormat displayFormat = DateFormat('yyyy-MM-dd');

  /// LABELS
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

  /// ICONS
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

  /// COLORS
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

  /// LOAD ALL DATA
  Future<void> _loadFromBackend() async {
    try {
      setState(() => loading = true);

      final prefs = await SharedPreferences.getInstance();
      final deviceInfo = DeviceInfoPlugin();
      final android = await deviceInfo.androidInfo;

      final res = await http.get(
        Uri.parse("https://dev.intelheart.unic.kg.ac.rs:82/api/app/data/all"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "pacijent": "1",
          "device": android.id,
        },
      );

      final List<dynamic> jsonList = jsonDecode(res.body);

      print("RESPONSE: ${res.body}");

      setState(() {
        cycles = jsonList
            .map((item) => CycleData(
          start: item["cycle_start_time"].toString(),
          end: item["cycle_end_time"].toString(),
          values: item,
        ))
            .toList();

        loading = false;
      });
    } catch (e) {
      loading = false;
      _showError("Error loading: $e");
    }
  }

  /// FILTER
  Future<void> _filter() async {
    if (filterStartDate == null || filterEndDate == null) {
      _showError("Select both FROM and TO dates");
      return;
    }

    try {
      setState(() => loading = true);

      final from = displayFormat.format(filterStartDate!);
      final to = displayFormat.format(filterEndDate!);

      final deviceInfo = DeviceInfoPlugin();
      final android = await deviceInfo.androidInfo;

      final res = await http.get(
        Uri.parse(
          "https://dev.intelheart.unic.kg.ac.rs:82/api/app/data/cycle-data/$from/$to",
        ),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "pacijent": "1",
          "device": android.id,
        },
      );

      final List<dynamic> jsonList = jsonDecode(res.body);

      print("RESPONSE: ${res.body}");
      setState(() {
        cycles = jsonList
            .map((item) => CycleData(
          start: item["cycle_start_time"].toString(),
          end: item["cycle_end_time"].toString(),
          values: item,
        ))
            .toList();
        loading = false;
      });
    } catch (e) {
      loading = false;
      _showError("Error filtering: $e");
    }
  }

  /// RESET
  void _reset() {
    setState(() {
      filterStartDate = null;
      filterEndDate = null;
    });
    _loadFromBackend();
  }

  /// PICK DATE
  Future<void> pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          filterStartDate = picked;
        } else {
          filterEndDate = picked;
        }
      });
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

      /// BODY
      body: Column(
        children: [
          const SizedBox(height: 14),

          /// FILTER CARD
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  /// FROM FIELD
                  TextField(
                    readOnly: true,
                    onTap: () => pickDate(isStart: true),
                    decoration: InputDecoration(
                      labelText: "From",
                      suffixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: filterStartDate == null
                          ? "Select date"
                          : displayFormat.format(filterStartDate!),
                    ),
                  ),
                  const SizedBox(height: 12),

                  /// TO FIELD
                  TextField(
                    readOnly: true,
                    onTap: () => pickDate(isStart: false),
                    decoration: InputDecoration(
                      labelText: "To",
                      suffixIcon: Icon(Icons.calendar_month),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: filterEndDate == null
                          ? "Select date"
                          : displayFormat.format(filterEndDate!),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _filter,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Filter",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _reset,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Reset"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          /// LIST
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : cycles.isEmpty
                ? const Center(child: Text("No data."))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cycles.length,
              itemBuilder: (context, index) {
                final c = cycles[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      childrenPadding: const EdgeInsets.all(16),
                      title: Text(
                        "${c.start} → ${c.end}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children:
                          fieldLabels.entries.map((entry) {
                            final key = entry.key;
                            final label = entry.value;

                            if (!c.values.containsKey(key)) {
                              return const SizedBox.shrink();
                            }

                            final val = c.values[key];

                            final color =
                                fieldColors[label] ?? Colors.grey;
                            final icon = fieldIcons[label];

                            return Container(
                              width:
                              (MediaQuery.of(context).size.width -
                                  60) /
                                  2,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius:
                                BorderRadius.circular(12),
                                border: Border.all(
                                  color: color.withOpacity(0.4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (icon != null)
                                    Icon(icon, color: color),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "$label: $val",
                                      maxLines: 3,
                                      overflow:
                                      TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
