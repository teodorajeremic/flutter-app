import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:table_calendar/table_calendar.dart';

class SkinTemperaturePage extends StatefulWidget {
  const SkinTemperaturePage({super.key});

  @override
  State<SkinTemperaturePage> createState() => _SkinTemperaturePageState();
}

class SkinTemperatureEntry {
  final DateTime startDate;
  final double SkinTemperature;

  SkinTemperatureEntry({
    required this.startDate,
    required this.SkinTemperature,
  });
}

class _SkinTemperaturePageState extends State<SkinTemperaturePage>
    with SingleTickerProviderStateMixin {
  DateTime clamp(DateTime day, DateTime first, DateTime last) {
    if (day.isBefore(first)) return first;
    if (day.isAfter(last)) return last;
    return day;
  }

  List<SkinTemperatureEntry> entries = [];
  List<SkinTemperatureEntry> filteredEntries = [];

  late TabController _tabController;

  DateTime? currentWindowEnd;
  DateTime _focusedDay30 = DateTime.now();
  DateTime _focusedDayAll = DateTime.now();

  final DateFormat displayDateFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _onTabChanged(_tabController.index);
    });

    _loadFromBackend();
  }

  Future<void> _loadFromBackend() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final patientId = prefs.getString('patientId') ?? '1';
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final deviceId = androidInfo.id;

      final url =
      Uri.parse("https://dev.intelheart.unic.kg.ac.rs:82/api/app/data/all");

      final res = await http.get(url, headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "pacijent": patientId.toString(),
        "device": deviceId,
      });

      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception("Server je vratio status: ${res.statusCode}");
      }

      final List<dynamic> jsonList = jsonDecode(res.body);
      final data = jsonList
          .where((item) =>
      item.containsKey("cycle_start_time") &&
          item.containsKey("skin_temp_celsius") &&
          item["skin_temp_celsius"] != null &&
          item["cycle_start_time"] != null)
          .map((item) {
        String raw = item["cycle_start_time"].toString().replaceAll(" ", "T");
        DateTime parsedDate = DateTime.parse(raw);
        double temp =
            double.tryParse(item["skin_temp_celsius"].toString()) ?? 0;
        return SkinTemperatureEntry(
            startDate: parsedDate, SkinTemperature: temp);
      }).toList();

      data.sort((a, b) => a.startDate.compareTo(b.startDate));

      if (mounted) {
        setState(() {
          entries = data;
          currentWindowEnd = _getEndOfWeek(DateTime.now());
          _filterLastWeek();
        });
      }
    } catch (e) {
      _showError("Greška pri učitavanju podataka sa backenda: $e");
    }
  }

  void _onTabChanged(int index) {
    switch (index) {
      case 0:
        currentWindowEnd = _getEndOfWeek(DateTime.now());
        _filterLastWeek();
        break;
      case 1:
        _focusedDay30 = DateTime.now();
        _filterLast30DaysFromFocused();
        break;
      case 2:
        _focusedDayAll = DateTime.now();
        _showAllData();
        break;
    }
  }

  DateTime _getEndOfWeek(DateTime date) {
    int daysToAdd = DateTime.sunday - date.weekday;
    if (daysToAdd < 0) daysToAdd += 7;
    return DateTime(date.year, date.month, date.day)
        .add(Duration(days: daysToAdd));
  }

  void _filterLastWeek() {
    if (currentWindowEnd == null) return;
    final startOfWeek = currentWindowEnd!.subtract(const Duration(days: 6));
    setState(() {
      filteredEntries = entries.where((e) {
        return (e.startDate.isAtSameMomentAs(startOfWeek) ||
            e.startDate.isAtSameMomentAs(currentWindowEnd!) ||
            (e.startDate.isAfter(startOfWeek) &&
                e.startDate.isBefore(currentWindowEnd!.add(Duration(days: 1)))));
      }).toList();
    });
  }

  void _filterLast30DaysFromFocused() {
    final end = _focusedDay30;
    final start = end.subtract(const Duration(days: 29));
    setState(() {
      filteredEntries = entries
          .where((e) => !e.startDate.isBefore(start) && !e.startDate.isAfter(end))
          .toList();
    });
  }

  void _showAllData() {
    setState(() {
      filteredEntries = entries;
    });
  }

  void _goPreviousWeek() {
    if (currentWindowEnd == null) return;
    setState(() {
      currentWindowEnd = currentWindowEnd!.subtract(const Duration(days: 7));
      _filterLastWeek();
    });
  }

  void _goNextWeek() {
    if (currentWindowEnd == null) return;
    final nextWeekEnd = currentWindowEnd!.add(const Duration(days: 7));
    if (nextWeekEnd.isAfter(_getEndOfWeek(DateTime.now()))) return;
    setState(() {
      currentWindowEnd = nextWeekEnd;
      _filterLastWeek();
    });
  }

  void _goPrevious30Days() {
    setState(() {
      _focusedDay30 = _focusedDay30.subtract(const Duration(days: 30));
      _filterLast30DaysFromFocused();
    });
  }

  void _goNext30Days() {
    final now = DateTime.now();
    if (_focusedDay30.add(const Duration(days: 30)).isAfter(now)) return;
    setState(() {
      _focusedDay30 = _focusedDay30.add(const Duration(days: 30));
      _filterLast30DaysFromFocused();
    });
  }

  String _getWeekRangeText() {
    switch (_tabController.index) {
      case 0:
        if (currentWindowEnd == null) return '';
        final startOfWeek = currentWindowEnd!.subtract(const Duration(days: 6));
        return '${displayDateFormat.format(startOfWeek)} - ${displayDateFormat.format(currentWindowEnd!)}';
      case 1:
        final end = _focusedDay30;
        final start = end.subtract(const Duration(days: 29));
        return '${displayDateFormat.format(start)} - ${displayDateFormat.format(end)}';
      case 2:
        if (entries.isEmpty) return '';
        final first = entries.first.startDate;
        final last = entries.last.startDate;
        return '${displayDateFormat.format(first)} - ${displayDateFormat.format(last)}';
      default:
        return '';
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Icon(Icons.error, color: Colors.red, size: 40),
        content: Text(message, textAlign: TextAlign.center),
      ),
    );
  }

  Widget buildNavigationRow(
      {VoidCallback? onPrev, VoidCallback? onNext, required String label}) {
    return SizedBox(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (onPrev != null)
            GestureDetector(
              onTap: onPrev,
              child: const Icon(Icons.arrow_back, size: 20, color: Colors.black54),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(label,
                style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          if (onNext != null)
            GestureDetector(
              onTap: onNext,
              child:
              const Icon(Icons.arrow_forward, size: 20, color: Colors.black54),
            ),
        ],
      ),
    );
  }

  Widget buildWeekView() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: filteredEntries.map((entry) {
        return Container(
          width: 90,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('EEEE\nMMM dd, yyyy').format(entry.startDate),
                style: const TextStyle(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              Text(
                DateFormat('HH:mm').format(entry.startDate),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                entry.SkinTemperature == 0
                    ? '--'
                    : entry.SkinTemperature.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: entry.SkinTemperature > 0
                      ? Colors.deepOrangeAccent
                      : Colors.grey,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget buildCalendarView(
      {required DateTime firstDay,
        required DateTime lastDay,
        required DateTime focusedDay,
        required ValueChanged<DateTime> onDayFocused}) {
    Map<DateTime, double> skinTempMap = {
      for (var entry in filteredEntries)
        DateTime(entry.startDate.year, entry.startDate.month, entry.startDate.day):
        entry.SkinTemperature,
    };

    return Transform.translate(
      offset: const Offset(0, -10),
      child: TableCalendar(
        firstDay: firstDay,
        lastDay: lastDay,
        focusedDay: _focusedDay30,
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          headerPadding: EdgeInsets.zero,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        daysOfWeekHeight: 30,
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
          weekendStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.redAccent,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            double? hr = skinTempMap[DateTime(day.year, day.month, day.day)];
            return Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: hr != null && hr > 0
                    ? Colors.deepOrangeAccent.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("${day.day}",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(hr != null && hr > 0 ? hr.toStringAsFixed(0) : "--",
                        style: TextStyle(
                          fontSize: 12,
                          color: hr != null && hr > 0
                              ? Colors.deepOrangeAccent
                              : Colors.grey,
                        )),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildChart() {
    return SizedBox(
      height: 250,
      child: SfCartesianChart(
        primaryXAxis: DateTimeAxis(
          intervalType: DateTimeIntervalType.days,
          dateFormat: DateFormat.MMMd(),
          interval: 1,
          edgeLabelPlacement: EdgeLabelPlacement.shift,
          majorTickLines: MajorTickLines(size: 0),
          minorTickLines: MinorTickLines(size: 0),
          majorGridLines: const MajorGridLines(width: 0),
          labelStyle: const TextStyle(color: Colors.transparent),
        ),
        primaryYAxis: NumericAxis(
          majorTickLines: MajorTickLines(size: 0),
          minorTickLines: MinorTickLines(size: 0),
          majorGridLines: const MajorGridLines(width: 1),
        ),
        series: <SplineAreaSeries<SkinTemperatureEntry, DateTime>>[
          SplineAreaSeries<SkinTemperatureEntry, DateTime>(
            dataSource: filteredEntries,
            xValueMapper: (e, _) => e.startDate,
            yValueMapper: (e, _) => e.SkinTemperature == 0 ? null : e.SkinTemperature,
            color: Colors.deepOrangeAccent.withOpacity(0.5),
            borderColor: Colors.deepOrangeAccent,
            borderWidth: 2,
            splineType: SplineType.monotonic,
            markerSettings: const MarkerSettings(isVisible: false),
            enableTooltip: false,
            emptyPointSettings: EmptyPointSettings(
              mode: EmptyPointMode.gap,
              color: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeekView = _tabController.index == 0;
    final is30DaysView = _tabController.index == 1;
    final isAllView = _tabController.index == 2;

    // Clamp za Last 30 Days
    DateTime firstDay30 = DateTime.now().subtract(const Duration(days: 29));
    DateTime lastDay30 = DateTime.now();
    DateTime focusedDay30Clamped = clamp(_focusedDay30, firstDay30, lastDay30);

    // Clamp za All
    DateTime firstDayAll = DateTime.now().subtract(Duration(days: 365));
    DateTime lastDayAll = DateTime.now().add(Duration(days: 365));

    //DateTime _focusedDayAll = DateTime.now();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.thermostat_outlined, color: Colors.white),
              SizedBox(width: 8),
              Text('Skin Temperature'),
            ],
          ),
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFFEF474B),
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Last Week'),
              Tab(text: 'Last 30 Days'),
              Tab(text: 'All'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
          ),
        ),
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                const SizedBox(height: 10),
                // Strelice i tekst opsega
                SizedBox(
                  height: 36,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isWeekView)
                        GestureDetector(
                          onTap: _goPreviousWeek,
                          child: const Icon(Icons.arrow_back, size: 20, color: Colors.black54),
                        )
                      else if (is30DaysView)
                        GestureDetector(
                          onTap: _goPrevious30Days,
                          child: const Icon(Icons.arrow_back, size: 20, color: Colors.black54),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          _getWeekRangeText(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      if (isWeekView)
                        GestureDetector(
                          onTap: _goNextWeek,
                          child: const Icon(Icons.arrow_forward, size: 20, color: Colors.black54),
                        )
                      else if (is30DaysView)
                        GestureDetector(
                          onTap: _goNext30Days,
                          child: const Icon(Icons.arrow_forward, size: 20, color: Colors.black54),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                // Grafikon
                SizedBox(
                  height: 250,
                  child: SfCartesianChart(
                    primaryXAxis: DateTimeAxis(
                      intervalType: DateTimeIntervalType.days,
                      dateFormat: DateFormat.MMMd(),
                      interval: 1,
                      edgeLabelPlacement: EdgeLabelPlacement.shift,
                      majorTickLines: MajorTickLines(size: 0),
                      minorTickLines: MinorTickLines(size: 0),
                      majorGridLines: const MajorGridLines(width: 0),
                      labelStyle: const TextStyle(color: Colors.transparent),
                    ),
                    primaryYAxis: NumericAxis(
                      majorTickLines: MajorTickLines(size: 0),
                      minorTickLines: MinorTickLines(size: 0),
                      majorGridLines: const MajorGridLines(width: 1),
                    ),
                    series: <SplineAreaSeries<SkinTemperatureEntry, DateTime>>[
                      SplineAreaSeries<SkinTemperatureEntry, DateTime>(
                        dataSource: filteredEntries,
                        xValueMapper: (e, _) => e.startDate,
                        yValueMapper: (e, _) => e.SkinTemperature == 0 ? null : e.SkinTemperature,
                        color: Colors.deepOrangeAccent.withOpacity(0.5),
                        borderColor: Colors.deepOrangeAccent,
                        borderWidth: 2,
                        splineType: SplineType.monotonic,
                        markerSettings: const MarkerSettings(isVisible: false),
                        enableTooltip: false,
                        emptyPointSettings: EmptyPointSettings(
                          mode: EmptyPointMode.gap,
                          color: Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 0),
                const SizedBox(height: 20),
                if (filteredEntries.isEmpty)
                  const Center(
                    child: Text(
                      'No Data Available',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                else if (isWeekView)
                  buildWeekView()
                else if (is30DaysView)
                    buildCalendarView(
                      firstDay: firstDayAll,
                      lastDay: lastDayAll,
                      focusedDay: _focusedDayAll,
                      onDayFocused: (focusedDay) {
                        setState(() {
                          _focusedDayAll = clamp(focusedDay, firstDayAll, lastDayAll);
                          //_filterLast30DaysFromFocused();
                        });
                      },
                    )
                  else if (isAllView)
                      buildCalendarView(
                        firstDay: firstDayAll,
                        lastDay: lastDayAll,
                        focusedDay: _focusedDayAll,
                        onDayFocused: (focusedDay) {
                          setState(() {
                            _focusedDayAll = clamp(focusedDay, firstDayAll, lastDayAll);
                          });
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

