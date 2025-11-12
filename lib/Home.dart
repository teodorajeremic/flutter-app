import 'package:bioirc/BRS.dart';
import 'package:bioirc/DASS.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'Authentication/Authentication.dart';
import 'CycleData.dart';
import 'HealthMetrices.dart';
import 'History/BloodOxygen.dart';
import 'History/SkinTemperature.dart';
import 'History/EnergyBurned.dart';
import 'History/AverageHeartRate.dart';
import 'DataFile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Profile.dart';

void main() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: HomeScreen()),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  String? displayName;
  int _selectedIndex = 0;

  final Map<String, Color> buttonColors = {
    'Skin Temperature': Color(0xFFCAF1DE),
    'Blood Oxygen': Color(0xFFF9EBDF),
    'Energy Burned': Color(0xFFEFF9DA),
  };

  final Map<String, IconData> fieldIcons = {
    'Skin Temperature': Icons.thermostat_outlined,
    'Blood Oxygen': Icons.bloodtype_outlined,
    'Energy Burned': Icons.local_fire_department_outlined,
  };

  final Map<String, Color> iconColors = {
    'Skin Temperature': Colors.blueAccent,
    'Blood Oxygen': Colors.brown,
    'Energy Burned': Colors.deepPurple,
  };

  final Map<String, Color> textColors = {
    'Skin Temperature': Colors.blueAccent,
    'Blood Oxygen': Colors.brown,
    'Energy Burned': Colors.deepPurple,
  };


  @override
  void initState() {
    super.initState();
    _loadUserName();

    // Set status bar icons to dark (for light background)
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
    );
  }

  void _loadUserName() {
    final user = _authService.currentUser;
    setState(() {
      displayName = (user?.displayName?.isNotEmpty ?? false)
          ? user!.displayName
          : "User";
    });
  }

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FilterByDate()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UploadCSVPage()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      );
    }
  }

  void _navigateToMetricPage(String metric) {
    switch (metric) {
      case 'Blood Oxygen':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BloodOxygenPage()),
        );
        break;
      case 'Skin Temperature':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SkinTemperaturePage()),
        );
        break;
      case 'Average Heart Rate':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AverageHeartRatePage()),
        );
        break;
      case 'Energy Burned':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EnergyBurnedPage()),
        );
        break;
      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$metric not implemented')));
    }
  }

  Widget _buildMetricGrid() {
    final metrics = buttonColors.keys.toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 items per row
        childAspectRatio:
        1.1, // adjust aspect ratio for smaller boxes (height > width)
        mainAxisSpacing: 8, // slightly smaller spacing
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            elevation: 0, // No shadow
            backgroundColor: buttonColors[metric],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            shadowColor: Colors.transparent,
          ),
          onPressed: () => _navigateToMetricPage(metric),
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
                  color: textColors[metric], // Use separate colors for each text
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 4.0,
                    ), // slight tweak for optical balance
                    child: Icon(
                      Icons.science_outlined,
                      // teodora
                      color: Color(0xFFEF474B),
                      size: 32,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          //'BioIRC',
                          'IntelHeart',
                          style: TextStyle(
                            //color: Color(0xFF54b574),
                            // teodora
                            color: Color(0xFFEF474B),
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // SizedBox(height: 2),
                        // Text(
                        //   'Research and Development Center',
                        //   style: TextStyle(
                        //     color: Color(0xFF54b574),
                        //     fontSize: 16,
                        //     fontWeight: FontWeight.w400,
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(
                color:
                Colors.grey[300], // or Color(0xFF54b574).withOpacity(0.3)
                thickness: 1,
                height: 20, // space above and below
              ),
              const SizedBox(height: 10),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  // color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  image: const DecorationImage(
                    // teodora
                    // image: AssetImage('assets/Banner.jpg'),
                    image: AssetImage('assets/Logo.png'),
                    //fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.medical_information_outlined,
                          color: Color(0xFF2C3E50),
                        ),
                        SizedBox(width: 5), // space between icon and text
                        Text(
                          'Health Metrics',
                          style: GoogleFonts.roboto(
                            textStyle: TextStyle(
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50), // Subtle dark blue-gray
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PastHistoryPage(),
                          ),
                        );
                      },
                      child: Text(
                        'View All',
                        style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF3498DB), // Soft, modern blue
                            // decoration: TextDecoration.none, // Removes underline
                            letterSpacing: 0, // Clean kerning
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: _buildMetricGrid(),
              ),
              const SizedBox(height: 30),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_turned_in_outlined,
                        color: Color(0xFF2C3E50),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Weekly Report',
                        style: GoogleFonts.roboto(
                          textStyle: TextStyle(
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 5),

                  // Tagline
                  Text(
                    'Submit Questionnaire Now',
                    style: GoogleFonts.roboto(
                      textStyle: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                        color: Colors.black54,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 20),

                  // Buttons centered
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DASSPage(),
                            ),
                          );
                        },
                        icon: Icon(Icons.psychology_outlined),
                        label: Text('DASS Test'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2980B9),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BRSPage(),
                            ),
                          );
                        },
                        icon: Icon(Icons.favorite_outline),
                        label: Text('BRS Test'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          // color: Colors.white, // background color of the whole bar
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onNavTapped,
            backgroundColor: Color(
              // teodora
              0xFFEF474B,
              //0xFF54b574,
            ), // keep consistent with container
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.white, // green for selected
            unselectedItemColor: Colors.white, // grey for unselected
            iconSize: 28,
            selectedLabelStyle: TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
            unselectedLabelStyle: TextStyle(fontSize: 12, height: 1.5),
            items: [
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(
                    top: 8.0,
                    bottom: 6.0,
                  ), // vertical padding on icon
                  child: Icon(Icons.calendar_today_outlined),
                ),
                label: 'Cycles',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 6.0),
                  child: Icon(Icons.file_copy_outlined),
                ),
                label: 'Data',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 6.0),
                  child: Icon(Icons.person),
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
