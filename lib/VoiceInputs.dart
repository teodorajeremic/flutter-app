import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

class UploadVoiceInputsPage extends StatefulWidget {
  const UploadVoiceInputsPage({super.key});

  @override
  State<UploadVoiceInputsPage> createState() => _UploadVoiceInputsPageState();
}

class _UploadVoiceInputsPageState extends State<UploadVoiceInputsPage> {
  List<File?> selectedFiles = List<File?>.filled(5, null, growable: false);
  bool isSending = false;

  Future<void> pickFile(int index) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFiles[index] = File(result.files.single.path!);
      });
    }
  }

  Future<void> uploadFiles() async {
    if (selectedFiles.any((f) => f == null)) {
      _showSnack("Izaberi svih 5 fajlova pre slanja.");
      return;
    }

    setState(() => isSending = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final patientId = prefs.getInt('patient_id');

      final deviceInfo = DeviceInfoPlugin();
      String deviceId = "";

      if (Theme.of(context).platform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id ?? "";
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? "";
      }

      // POST upload
      final uploadUri = Uri.parse(
        "https://dev.intelheart.unic.kg.ac.rs:82/api/app/voice",
      );

      var request = http.MultipartRequest("POST", uploadUri);
      request.headers.addAll({
        "Accept": "application/json",
        "pacijent": "1",
        "device": deviceId,
      });

      for (final file in selectedFiles) {
        request.files.add(
          await http.MultipartFile.fromPath("voices[]", file!.path),
        );
      }

      final streamedResponse = await request.send();
      final uploadResponseBody =
      await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode != 200 &&
          streamedResponse.statusCode != 201) {
        throw Exception(
          "Server error (${streamedResponse.statusCode}):\n$uploadResponseBody",
        );
      }

      // // Nakon uspešnog POST → GET rezultat
      // final resultUri = Uri.parse(
      //   "https://dev.intelheart.unic.kg.ac.rs:82/api/app/voice",
      // );
      //
      // final resultResponse = await http.get(
      //   resultUri,
      //   headers: {
      //     "Accept": "application/json",
      //     "pacijent": "1",
      //     "device": deviceId,
      //   },
      // );
      //
      // setState(() => isSending = false);
      //
      // if (resultResponse.statusCode == 200) {
      //   _showResultDialog(resultResponse.body);
      //   print(resultResponse.body);
      // } else {
      //   _showResultDialog(
      //     "Greška pri dobijanju rezultata (${resultResponse.statusCode}):\n${resultResponse.body}",
      //   );
      // }
      // Nakon uspešnog POST → GET rezultat
      final resultUri = Uri.parse(
        "https://dev.intelheart.unic.kg.ac.rs:82/api/app/voice",
      );

      final resultResponse = await http.get(
        resultUri,
        headers: {
          "Accept": "application/json",
          "pacijent": "1",
          "device": deviceId,
        },
      );

      // spinner
      await Future.delayed(const Duration(seconds: 10));

      setState(() => isSending = false);

      if (resultResponse.statusCode == 200) {
        _showResultDialog(resultResponse.body);
        print(resultResponse.body);
      } else {
        _showResultDialog(
          "Greška pri dobijanju rezultata (${resultResponse.statusCode}):\n${resultResponse.body}",
        );
      }
    } catch (e) {
      setState(() => isSending = false);
      _showResultDialog("Došlo je do greške:\n\n$e");
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _showResultDialog(String result) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Rezultat"),
        content: Text(
          result,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  Widget _buildFileButton(int index) {
    final file = selectedFiles[index];

    return ElevatedButton.icon(
      onPressed: () => pickFile(index),
      icon: const Icon(Icons.upload_file),
      label: Text(
        file == null ? "Izaberi fajl ${index + 1}" : file.path.split('/').last,
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 4,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text("Upload 5 Voice Inputs"),
            backgroundColor: const Color(0xFFEF474B),
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < 5; i++) ...[
                  _buildFileButton(i),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isSending ? null : uploadFiles,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Pošalji"),
                ),
              ],
            ),
          ),
        ),
        if (isSending) _buildLoadingOverlay(),
      ],
    );
  }
}
