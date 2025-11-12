import 'package:flutter/material.dart';
import 'History/BloodOxygen.dart';
import 'History/SkinTemperature.dart';
import 'History/EnergyBurned.dart';
import 'History/AverageHeartRate.dart';

class PastHistoryPage extends StatelessWidget {
  const PastHistoryPage({super.key});

  final Map<String, Color> buttonColors = const {
    'Skin Temperature': Color(0xFFCAF1DE),
    'Blood Oxygen': Color(0xFFF9EBDF),
    'Energy Burned': Color(0xFFEFF9DA),
    'Average Heart Rate': Color(0xFFD3F4FF),
  };

  final Map<String, IconData> fieldIcons = const {
    'Skin Temperature': Icons.thermostat_outlined,
    'Blood Oxygen': Icons.bloodtype_outlined,
    'Energy Burned': Icons.local_fire_department_outlined,
    'Average Heart Rate': Icons.monitor_heart_outlined,
  };

  final Map<String, Color> iconColors = const {
    'Skin Temperature': Colors.blueAccent,
    'Blood Oxygen': Colors.brown,
    'Energy Burned': Colors.deepPurple,
    'Average Heart Rate': Color(0xFF651F37),
  };

  final Map<String, Color> textColors = const {
    'Skin Temperature': Colors.blueAccent,
    'Blood Oxygen': Colors.brown,
    'Energy Burned': Colors.deepPurple,
    'Average Heart Rate': Color(0xFF651F37),
  };

  void _navigateToMetricPage(BuildContext context, String metric) {
    Widget? page;
    switch (metric) {
      case 'Blood Oxygen':
        page = const BloodOxygenPage();
        break;
      case 'Skin Temperature':
        page = const SkinTemperaturePage();
        break;
      case 'Average Heart Rate':
        page = const AverageHeartRatePage();
        break;
      case 'Energy Burned':
        page = const EnergyBurnedPage();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$metric not implemented')),
        );
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page!));
  }

  Widget _buildMetricGrid(BuildContext context) {
    final metrics = buttonColors.keys.toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.1,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: buttonColors[metric],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            shadowColor: Colors.transparent,
          ),
          onPressed: () => _navigateToMetricPage(context, metric),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(fieldIcons[metric], size: 25, color: iconColors[metric]),
              const SizedBox(height: 4),
              Text(
                metric,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: textColors[metric],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.medical_information_outlined, color: Colors.white),
            SizedBox(width: 8),
            Text('Health Metrics'),
          ],
        ),
        backgroundColor: const Color(0xFFEF474B),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMetricGrid(context),
            ],
          ),
        ),
      ),
    );
  }
}
