import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class UploadVoiceInputsPage extends StatefulWidget {
  const UploadVoiceInputsPage({super.key});

  @override
  State<UploadVoiceInputsPage> createState() => _UploadVoiceInputsPageState();
}

class _UploadVoiceInputsPageState extends State<UploadVoiceInputsPage> {
  List<File> selectedFiles = [];
  bool isSending = false;

  // Pick exactly 5 MP4 files
  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      //allowedExtensions: ['mp4'],
      allowMultiple: true,
    );

    if (result != null) {
      final files = result.paths.whereType<String>().map((path) => File(path)).toList();

      // ovde treba da bude 5
      if (files.length != 1) {
        _showSnack("Moraš izabrati TAČNO 5 audio fajlova.");
        return;
      }

      setState(() {
        selectedFiles = files;
      });
    }
  }

  // Send to backend
  Future<void> uploadFiles() async {
    if (selectedFiles.length != 5) {
      _showSnack("Izaberi 5 fajlova pre slanja.");
      return;
    }

    setState(() => isSending = true);

    // final uri = Uri.parse("https://tvoj-server.com/api/upload-voice"); // PROMENI OVO
    //
    // var request = http.MultipartRequest("POST", uri);
    //
    // for (int i = 0; i < selectedFiles.length; i++) {
    //   request.files.add(
    //     await http.MultipartFile.fromPath("file${i + 1}", selectedFiles[i].path),
    //   );
    // }
    //
    // var response = await request.send();
    // var body = await response.stream.bytesToString();
    //
    // setState(() => isSending = false);
    //
    // _showResultDialog(body);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // void _showResultDialog(String result) {
  //   showDialog(
  //     context: context,
  //     builder: (_) => AlertDialog(
  //       title: const Text("Rezultat analize"),
  //       content: Text(
  //         result,
  //         style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //       ),
  //       actions: [
  //         TextButton(
  //           child: const Text("OK"),
  //           onPressed: () => Navigator.pop(context),
  //         )
  //       ],
  //     ),
  //   );
  // }

  // Full-screen loading overlay
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

  // UI card for each file
  Widget _buildFileCard(File file) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.audiotrack, color: Colors.blue, size: 30),
        title: Text(file.path.split('/').last),
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

                ElevatedButton.icon(
                  onPressed: pickFiles,
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Izaberi 5 audio fajlova"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),

                const SizedBox(height: 20),

                if (selectedFiles.isNotEmpty)
                  const Text("Izabrani fajlovi:",
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),

                const SizedBox(height: 10),

                Expanded(
                  child: ListView(
                    children: selectedFiles.map(_buildFileCard).toList(),
                  ),
                ),

                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: isSending ? null : uploadFiles,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Posalji"),
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
