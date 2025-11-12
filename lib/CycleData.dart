import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'Authentication/Authentication.dart';
import 'DataFile.dart';

class FilterByDate extends StatefulWidget {
  const FilterByDate({super.key});

  @override
  State<FilterByDate> createState() => _FilterByDateState();
}
// svaki red u csv fajlu je jedan ciklus
class CycleData {
  final String cycleStartTimeStr;
  final String cycleEndTimeStr;
  final Map<String, dynamic> values;

  CycleData({
    required this.cycleStartTimeStr,
    required this.cycleEndTimeStr,
    required this.values,
  });
}

class _FilterByDateState extends State<FilterByDate> {
  List<List<dynamic>>? csvTable; // ceo csv fajl kao tabela(lista redova i kolona)
  List<CycleData> cycleDataList = []; // filtrirani podaci koji se prikazuju
  bool csvLoaded = false; // da li je csv ucitan

  DateTime? filterStartDate;
  DateTime? filterEndDate;

  final DateFormat customFormat = DateFormat("dd-MM-yy HH:mm");
  final AuthService _authService = AuthService();

  String drawerMessage = '';

  final Map<String, String> fieldLabels = {
    'Cycle start time': 'Cycle Start',
    'Cycle end time': 'Cycle End',
    'Resting heart rate (bpm)': 'Resting Heart Rate \n (BPM)',
    'Heart rate variability (ms)': 'Heart Rate Variability \n (MS)',
    'Skin temp (celsius)': 'Skin Temperature \n (C°)',
    'Blood oxygen %': 'Blood Oxygen Level \n (%)',
    'Energy burned (cal)': 'Energy Burned \n (Calories)',
    'Max HR (bpm)': 'Max Heart Rate \n (BPM)',
    'Sleep onset': 'Sleep Time',
    'Wake onset': 'Wake Time',
    'Average HR (bpm)': 'Average Heart Rate \n (BPM)',
    'Respiratory rate (rpm)': 'Respiratory Rate \n (RPM)',
    'Asleep duration (min)': 'Asleep Time \n (Hours)',
    'In bed duration (min)': 'InBed Duration \n (Hours)',
    'Light sleep duration (min)': 'Light Sleep \n (Hours)',
    'Deep (SWS) duration (min)': 'Deep Sleep \n (Hours)',
    'REM duration (min)': 'REM Sleep \n (Hours)',
    'Awake duration (min)': 'Awake Time \n (Hours)',
    'Sleep need (min)': 'Sleep Needed \n (Hours)',
    'Sleep debt (min)': 'Sleep Debt \n (Hours)',
  };

  final List<String> minuteFields = [
    'Asleep duration (min)',
    'In bed duration (min)',
    'Light sleep duration (min)',
    'Deep (SWS) duration (min)',
    'REM duration (min)',
    'Awake duration (min)',
    'Sleep need (min)',
    'Sleep debt (min)',
  ];
  bool showDateSelection = false; // add this to your State

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
  String _getFieldDescription(String fieldKey) {
    switch (fieldKey) {
      case 'Resting heart rate (bpm)':
        return "Your resting heart rate (RHR) measures how many times your heart beats per minute while at rest. Lower values often indicate better cardiovascular fitness.";
      case 'Heart rate variability (ms)':
        return "HRV shows the variation in time between heartbeats. Higher HRV generally means better recovery and lower stress.";
      case 'Skin temp (celsius)':
        return "Skin temperature changes can indicate recovery, illness, or changes in environment.";
      case 'Blood oxygen %':
        return "The percentage of oxygen in your blood. Normal values are typically 95–100%.";
      case 'Asleep duration (min)':
        return "Total time spent asleep during the cycle.";
      case 'Deep (SWS) duration (min)':
        return "Time spent in slow-wave (deep) sleep, important for recovery.";
      default:
        return "No description available.";
    }
  }

  final Map<String, Color> fieldColors = {
    'Cycle start time': Colors.green,
    'Cycle end time': Colors.red,
    'Resting heart rate (bpm)': Colors.pink,
    'Heart rate variability (ms)': Colors.deepPurple,
    'Skin temp (celsius)': Colors.orange,
    'Blood oxygen %': Colors.blue,
    'Energy burned (cal)': Colors.red,
    'Max HR (bpm)': Colors.redAccent,
    'Average HR (bpm)': Colors.purple,
    'Sleep onset': Colors.indigo,
    'Wake onset': Colors.lightBlue,
    'Respiratory rate (rpm)': Colors.cyan,
    'Asleep duration (min)': Colors.teal,
    'In bed duration (min)': Colors.brown,
    'Light sleep duration (min)': Colors.lightGreen,
    'Deep (SWS) duration (min)': Colors.deepOrange,
    'REM duration (min)': Colors.blueGrey,
    'Awake duration (min)': Colors.grey,
    'Sleep need (min)': Colors.black,
    'Sleep debt (min)': Colors.redAccent,
  };

  @override
  void initState() {
    super.initState();
    _loadStoredCSV();
  }

  Future<void> _loadStoredCSV() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.csv'))
          .toList();
      if (files.isNotEmpty) {
        final file = files.first;
        final content = await file.readAsString();
        //final table = const CsvToListConverter().convert(content);
        final table = const CsvToListConverter(eol: '\n').convert(content);
        if (table.isNotEmpty) {
          setState(() {
            csvTable = table;
            csvLoaded = true;
          });

          // redovi
         for (int i = 0; i < csvTable!.length; i++) {
          print('ROW $i: ${csvTable?[i]}');
         }
        } else {
          _showError("Stored CSV file is empty or corrupted.");
        }
      } else {
        _showError("No stored CSV file found.");
      }
    } catch (e) {
      _showError("Failed to load CSV file: $e");
    }
  }

  String displayValue(String field, dynamic value) {
    if (value == null) return 'N/A';
    if (minuteFields.contains(field)) {
      final double minutes = double.tryParse(value.toString()) ?? 0;
      return (minutes / 60).toStringAsFixed(2);
    }
    return value.toString();
  }

  void filterDataByDateRange() {
    print("csvTable == null? ${csvTable == null}");
    print("csvTable length: ${csvTable?.length}");
    if (csvTable == null || csvTable!.length < 2) {
      _showError("CSV data not loaded properly.");
      return;
    }
    if (filterStartDate == null || filterEndDate == null) {
      _showError("Please select both start and end dates.");
      return;
    }

    final start = DateTime(
      filterStartDate!.year,
      filterStartDate!.month,
      filterStartDate!.day,
    );
    final end = DateTime(
      filterEndDate!.year,
      filterEndDate!.month,
      filterEndDate!.day,
      23,
      59,
      59,
    );
    final headers = csvTable!.first.map((e) => e.toString().trim()).toList();

    final idxStart = headers.indexWhere(
      (h) => h.toLowerCase() == 'cycle start time',
    );
    final idxEnd = headers.indexWhere(
      (h) => h.toLowerCase() == 'cycle end time',
    );

    if (idxStart == -1 || idxEnd == -1) {
      _showError("Cycle start/end columns not found.");
      return;
    }

    final List<CycleData> filtered = [];

    for (int i = 1; i < csvTable!.length; i++) {
      final row = csvTable![i];
      if (idxStart >= row.length || idxEnd >= row.length) continue;

      final startStr = row[idxStart].toString().trim();
      final endStr = row[idxEnd].toString().trim();

      DateTime? startTime;
      DateTime? endTime;
      try {
        startTime = customFormat.parse(startStr);
        endTime = customFormat.parse(endStr);
      } catch (_) {
        continue;
      }

      if (startTime.isBefore(start) || endTime.isAfter(end)) continue;

      final values = <String, dynamic>{};
      for (final field in fieldLabels.keys) {
        final idx = headers.indexWhere(
          (h) => h.trim().toLowerCase() == field.toLowerCase(),
        );
        if (idx != -1 && idx < row.length) values[field] = row[idx];
      }

      filtered.add(
        CycleData(
          cycleStartTimeStr: startStr,
          cycleEndTimeStr: endStr,
          values: values,
        ),
      );
    }

    setState(() {
      cycleDataList = filtered;
    });

    if (filtered.isEmpty) {
      _showError("No data found in selected date range.");
    }
  }

  Future<void> pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (filterStartDate ?? DateTime.now())
          : (filterEndDate ?? DateTime.now()),
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
        cycleDataList = [];
      });

      // Trigger filtering immediately if both dates are set
      if (filterStartDate != null && filterEndDate != null) {
        filterDataByDateRange();
      }
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.error_outline, color: Colors.red, size: 40),
        content: Text(message, textAlign: TextAlign.center),
      ),
    );
  }

  String formatDate(DateTime? date) =>
      date != null ? DateFormat('yyyy-MM-dd').format(date) : "Select Date";

  Widget _buildDataBox(String fieldKey, dynamic value) {
    final icon = fieldIcons[fieldKey];
    final color = fieldColors[fieldKey] ?? Colors.black;

    return SizedBox(
      width: 130,
      child: Container(
        margin: const EdgeInsets.all(5),
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // Main content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) Icon(icon, size: 20, color: color),
                  const SizedBox(height: 5),
                  Text(
                    fieldLabels[fieldKey] ?? fieldKey,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    displayValue(fieldKey, value),
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Info button on top-right
            Positioned(
              top: -15,
              right: -5,
              child: IconButton(
                icon: const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: Colors.grey,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Row(
                        children: [
                          Icon(Icons.info_outline, color: color),
                          const SizedBox(width: 8),
                          Text(fieldLabels[fieldKey] ?? fieldKey),
                        ],
                      ),
                      content: Text(
                        _getFieldDescription(fieldKey),
                        style: const TextStyle(fontSize: 14),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Close"),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTwoColumnGrid(Map<String, dynamic> values) {
    final keys = fieldLabels.keys.toList();
    final rows = <Widget>[];
    for (int i = 0; i < keys.length; i += 2) {
      final field1 = keys[i];
      final field2 = (i + 1 < keys.length) ? keys[i + 1] : null;
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDataBox(field1, values[field1]),
            if (field2 != null)
              _buildDataBox(field2, values[field2])
            else
              const Spacer(),
          ],
        ),
      );
    }
    return Column(children: rows);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.calendar_today_outlined, color: Colors.white),
            SizedBox(width: 8),
            Text('Detailed Cycle Data'),
          ],
        ),
        //backgroundColor: Color(0xFF54b574),
        backgroundColor: Color(0xFFEF474B),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 50),
        child: Center(
          child: Column(
            children: [
              if (csvLoaded) ...[
                if (!showDateSelection)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(
                              color: Colors.red,
                              width: 1.2,
                            ),
                          ),
                        ),
                        onPressed: () async {
                          final choice = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Row(
                                children: const [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.redAccent,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Important",
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 22,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                              content: const Text(
                                "Do You Want To Upload A New Data Or Proceed With Old ?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                  ),
                                  child: const Text("Upload"),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor:
                                        Colors.green,
                                  ),
                                  child: const Text("Proceed"),
                                ),
                              ],
                            ),
                          );

                          if (choice == true) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UploadCSVPage(),
                              ),
                            );
                          } else if (choice == false) {
                            setState(() => showDateSelection = true);
                          }
                        },
                        icon: const Icon(Icons.info_outline),
                        label: const Text(
                          'Important Instructions',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (showDateSelection) ...[
                  const Text(
                    'Select Cycle Date',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () => pickDate(isStart: true),
                        icon: const Icon(
                          Icons.date_range,
                          color: Colors.white,
                          size: 15,
                        ),
                        label: Text(
                          "Start: ${formatDate(filterStartDate)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () => pickDate(isStart: false),
                        icon: const Icon(
                          Icons.date_range_outlined,
                          color: Colors.white,
                          size: 15,
                        ),
                        label: Text(
                          "End: ${formatDate(filterEndDate)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                ],
              ],
              ...cycleDataList.map(
                (data) => Card(
                  clipBehavior: Clip.antiAlias,
                  color: Colors.grey[100],
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  "${DateFormat('dd-MM-yyyy').format(customFormat.parse(data.cycleStartTimeStr))} ",
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            const TextSpan(
                              text: "TO",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text:
                                  " ${DateFormat('dd-MM-yyyy').format(customFormat.parse(data.cycleEndTimeStr))}",
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: _buildTwoColumnGrid(data.values),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
