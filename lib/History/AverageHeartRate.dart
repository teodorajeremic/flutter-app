import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:table_calendar/table_calendar.dart';

class AverageHeartRatePage extends StatefulWidget {
  const AverageHeartRatePage({super.key});

  @override
  State<AverageHeartRatePage> createState() => _AverageHeartRatePageState();
}

class AverageHeartRateEntry {
  final DateTime startDate;
  final double averageHeartRate;

  AverageHeartRateEntry({
    required this.startDate,
    required this.averageHeartRate,
  });
}

class _AverageHeartRatePageState extends State<AverageHeartRatePage>
    with SingleTickerProviderStateMixin {
  List<AverageHeartRateEntry> entries = [];
  List<AverageHeartRateEntry> filteredEntries = [];
  DateTime clamp(DateTime day, DateTime first, DateTime last) {
    if (day.isBefore(first)) return first;
    if (day.isAfter(last)) return last;
    return day;
  }

  DateTime? currentWindowEnd;
  late TabController _tabController;

  final DateFormat csvDateFormat = DateFormat('dd-MM-yy HH:mm');
  final DateFormat displayDateFormat = DateFormat('MMM dd, yyyy');

  // For calendar focused days in 30 days and all tabs
  DateTime _focusedDay30 = DateTime.now();
  DateTime _focusedDayAll = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _onTabChanged(_tabController.index);
    });

    _loadStoredCSV();
  }

  Future<void> _loadStoredCSV() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final csvFiles = directory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.csv'))
          .toList();

      if (csvFiles.isEmpty) {
        _showError("No CSV file found in local storage.");
        return;
      }

      final file = csvFiles.first;
      final csvContent = await file.readAsString();
      final rows = const CsvToListConverter().convert(csvContent, eol: '\n');

      final header = rows.first.map((e) => e.toString().trim()).toList();
      final startIndex = header.indexOf('Cycle start time');
      final tempIndex = header.indexOf('Average HR (bpm)');

      if (startIndex == -1 || tempIndex == -1) {
        _showError("Missing required columns in CSV.");
        return;
      }

      final data = rows
          .skip(1)
          .where(
            (row) =>
        row.length > tempIndex &&
            row.length > startIndex &&
            row[tempIndex] != null &&
            row[startIndex] != null,
      )
          .map((row) {
        DateTime parsedDate = csvDateFormat.parse(
          row[startIndex].toString(),
        );
        double temp = double.tryParse(row[tempIndex].toString()) ?? 0;
        return AverageHeartRateEntry(
          startDate: parsedDate,
          averageHeartRate: temp,
        );
      })
          .toList();

      data.sort((a, b) => a.startDate.compareTo(b.startDate));

      setState(() {
        entries = data;
        currentWindowEnd = _getEndOfWeek(DateTime.now());
      });

      _filterLastWeek();
    } catch (e) {
      _showError("Error reading CSV file: $e");
    }
  }

  void _onTabChanged(int index) {
    switch (index) {
      case 0:
        currentWindowEnd = _getEndOfWeek(DateTime.now());
        _filterLastWeek();
        break;
      case 1:
        currentWindowEnd = null;
        _focusedDay30 = DateTime.now();
        _filterLast30Days();
        break;
      case 2:
        currentWindowEnd = null;
        _focusedDayAll = DateTime.now();
        _showAllData();
        break;
    }
  }

  DateTime _getEndOfWeek(DateTime date) {
    int daysToAdd = DateTime.sunday - date.weekday;
    if (daysToAdd < 0) daysToAdd += 7;
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).add(Duration(days: daysToAdd));
  }

  void _filterLastWeek() {
    if (currentWindowEnd == null) return;
    final startOfWeek = currentWindowEnd!.subtract(const Duration(days: 6));
    setState(() {
      filteredEntries = entries.where((e) {
        return e.startDate.isAtSameMomentAs(startOfWeek) ||
            e.startDate.isAtSameMomentAs(currentWindowEnd!) ||
            (e.startDate.isAfter(startOfWeek) &&
                e.startDate.isBefore(
                  currentWindowEnd!.add(const Duration(days: 1)),
                ));
      }).toList();
    });
  }

  void _filterLast30Days() {
    final now = DateTime.now();
    final past30Days = now.subtract(const Duration(days: 29));
    setState(() {
      filteredEntries = entries
          .where(
            (e) =>
        !e.startDate.isBefore(past30Days) && !e.startDate.isAfter(now),
      )
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
    setState(() {
      DateTime nextWeekEnd = currentWindowEnd!.add(const Duration(days: 7));
      if (nextWeekEnd.isAfter(_getEndOfWeek(DateTime.now()))) {
        return;
      }
      currentWindowEnd = nextWeekEnd;
      _filterLastWeek();
    });
  }

  String _getWeekRangeText() {
    switch (_tabController.index) {
      case 0:
        if (currentWindowEnd == null) return '';
        final startOfWeek = currentWindowEnd!.subtract(const Duration(days: 6));
        return '${displayDateFormat.format(startOfWeek)} - ${displayDateFormat.format(currentWindowEnd!)}';
      case 1:
        final now = DateTime.now();
        final past30Days = now.subtract(const Duration(days: 29));
        return '${displayDateFormat.format(past30Days)} - ${displayDateFormat.format(now)}';
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
                entry.averageHeartRate == 0
                    ? '--'
                    : entry.averageHeartRate.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: entry.averageHeartRate > 0
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

  Widget buildCalendarView({required DateTime firstDay, required DateTime lastDay, required DateTime focusedDay, required ValueChanged<DateTime> onDayFocused}) {
    Map<DateTime, double> heartRateMap = {
      for (var entry in filteredEntries)
        DateTime(entry.startDate.year, entry.startDate.month, entry.startDate.day):
        entry.averageHeartRate,
    };

    return Transform.translate(
      offset: const Offset(0, -10), // Move calendar up by 10 pixels
      child: TableCalendar(
        firstDay: firstDay,
        lastDay: lastDay,
        focusedDay: focusedDay,
        startingDayOfWeek: StartingDayOfWeek.monday, // <-- Set Monday as first day
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          headerPadding: EdgeInsets.zero, // Remove header padding to reduce gap
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
            double? hr = heartRateMap[DateTime(day.year, day.month, day.day)];
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
                    Text(
                      "${day.day}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hr != null && hr > 0 ? hr.toStringAsFixed(0) : "--",
                      style: TextStyle(
                        fontSize: 12,
                        color: hr != null && hr > 0
                            ? Colors.deepOrangeAccent
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        onPageChanged: onDayFocused,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeekView = _tabController.index == 0;
    final is30DaysView = _tabController.index == 1;
    final isAllView = _tabController.index == 2;

    DateTime firstDateAll = entries.isEmpty
        ? DateTime.now().subtract(const Duration(days: 365))
        : entries.first.startDate;
    DateTime lastDateAll = entries.isEmpty ? DateTime.now() : entries.last.startDate;

    // Clamp focusedDayAll so it stays inside valid range
    _focusedDayAll = clamp(_focusedDayAll, firstDateAll, lastDateAll);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.monitor_heart_outlined, color: Colors.white),
              SizedBox(width: 8),
              Text('Average Heart Rate'),
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
                SizedBox(
                  height: 36,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isWeekView)
                        GestureDetector(
                          onTap: _goPreviousWeek,
                          child: const Icon(
                            Icons.arrow_back,
                            size: 20,
                            color: Colors.black54,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          _getWeekRangeText(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (isWeekView)
                        GestureDetector(
                          onTap: _goNextWeek,
                          child: const Icon(
                            Icons.arrow_forward,
                            size: 20,
                            color: Colors.black54,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
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
                    series: <SplineAreaSeries<AverageHeartRateEntry, DateTime>>[
                      SplineAreaSeries<AverageHeartRateEntry, DateTime>(
                        dataSource: filteredEntries,
                        xValueMapper: (e, _) => e.startDate,
                        yValueMapper: (e, _) =>
                        e.averageHeartRate == 0 ? null : e.averageHeartRate,
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
                Divider(height: 0),
                SizedBox(height: 20),
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
                      firstDay: DateTime.now().subtract(const Duration(days: 29)),
                      lastDay: DateTime.now(),
                      focusedDay: _focusedDay30,
                      onDayFocused: (focusedDay) {
                        setState(() {
                          _focusedDay30 = focusedDay;
                        });
                      },
                    )
                  else if (isAllView)
                      buildCalendarView(
                        firstDay: firstDateAll,
                        lastDay: lastDateAll,
                        focusedDay: _focusedDayAll,
                        onDayFocused: (focusedDay) {
                          setState(() {
                            _focusedDayAll = focusedDay;
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
