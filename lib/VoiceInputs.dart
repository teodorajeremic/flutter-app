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
  // Lista od 5 fajlova, inicijalno null
  List<File?> selectedFiles = List<File?>.filled(5, null, growable: false);
  bool isSending = false;

  // Pick a single file for a specific index
  Future<void> pickFile(int index) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFiles[index] = File(result.files.single.path!);
      });
    }
  }

  // Upload all files
  Future<void> uploadFiles() async {
    // Provera da li su svi fajlovi izabrani
    if (selectedFiles.any((file) => file == null)) {
      _showSnack("Izaberi svih 5 fajlova pre slanja.");
      return;
    }

    setState(() => isSending = true);

    final uri = Uri.parse("https://tvoj-server.com/api/upload-voice"); // PROMENI OVO
    var request = http.MultipartRequest("POST", uri);

    for (int i = 0; i < selectedFiles.length; i++) {
      final file = selectedFiles[i]!;
      request.files.add(
        await http.MultipartFile.fromPath("file${i + 1}", file.path),
      );
    }

    var response = await request.send();
    var body = await response.stream.bytesToString();

    setState(() => isSending = false);

    _showResultDialog(body);
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
        title: const Text("Rezultat analize"),
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
      label: Text(file == null ? "Izaberi fajl ${index + 1}" : file.path.split('/').last),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

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
                // 5 dugmadi
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
