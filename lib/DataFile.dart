import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

class UploadCSVPage extends StatefulWidget {
  const UploadCSVPage({super.key});

  @override
  State<UploadCSVPage> createState() => _UploadCSVPageState();
}

class _UploadCSVPageState extends State<UploadCSVPage> {
  String? _filePath;
  String? _fileName; // Dodajemo promenljivu za naziv fajla
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadLastUploadedFile();
  }

  Future<void> _loadLastUploadedFile() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFile = prefs.getString('last_uploaded_file');
    if (lastFile != null) {
      setState(() {
        _fileName = lastFile; // postavljamo naziv fajla
        _statusMessage = "Last uploaded file: $lastFile";
      });
    }
  }

  Future<void> _pickAndUploadFile() async {
    setState(() {
      _statusMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        String? path = file.path;
        if (path == null) throw Exception('Could not get file path.');

        setState(() {
          _filePath = path;
          _fileName = path.split('/').last; // odmah postavljamo naziv fajla
        });

        await _uploadCsvToBackend(path);
      } else {
        setState(() {
          _statusMessage = 'File picking cancelled.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _uploadCsvToBackend(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      setState(() {
        _statusMessage = "CSV file does not exist.";
      });
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final patientId = prefs.getInt('patient_id');

      final deviceInfo = DeviceInfoPlugin();
      String deviceId = '';
      if (Theme.of(context).platform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id ?? '';
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
      }

      final url = Uri.parse(
          "https://dev.intelheart.unic.kg.ac.rs:82/api/app/data/upload");

      final request = http.MultipartRequest("POST", url);
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      request.headers.addAll({
        "Content-Type": "application/json",
        "Accept": "application/json",
        "pacijent": "1",
        "device": deviceId,
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final fileName = file.path.split('/').last;
        await prefs.setString('last_uploaded_file', fileName);

        setState(() {
          _fileName = fileName; // uvek prikazujemo naziv fajla
          _statusMessage = "CSV '$fileName' successfully uploaded!";
        });
      } else {
        setState(() {
          _statusMessage = "Error ${response.statusCode}: $responseBody";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Upload failed: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Upload CSV',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFEF474B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: _pickAndUploadFile,
                icon: const Icon(Icons.upload_file, size: 20),
                label: const Text(
                  'Pick and Upload CSV',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF474B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(180, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 5,
                ),
              ),
              const SizedBox(height: 20),
              if (_fileName != null) // Prikaz naziva fajla uvek
                Text(
                  "Selected file: $_fileName",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              const SizedBox(height: 10),
              if (_statusMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _statusMessage!.startsWith('Error')
                        ? Colors.red.shade100
                        : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _statusMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _statusMessage!.startsWith('Error')
                          ? Colors.red.shade800
                          : Colors.blue.shade800,
                      fontWeight: FontWeight.w600,
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
