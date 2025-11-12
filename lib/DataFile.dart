import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

// za upload csv fajla
class UploadCSVPage extends StatefulWidget {
  const UploadCSVPage({super.key});

  @override
  State<UploadCSVPage> createState() => _UploadCSVPageState();
}

class _UploadCSVPageState extends State<UploadCSVPage> {
  String? _fileName;
  String? _filePath;
  String? _statusMessage;
  DateTime? _uploadDate;

  @override
  void initState() {
    super.initState();
    _loadExistingFile();
  }
// proverara da li vec postoji csv fajl u lokalnoj memoriji
  Future<void> _loadExistingFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      print('Looking for files in directory: ${directory.path}');

      // lista svih fajlova
      final allFiles = directory.listSync().whereType<File>().toList();
      print('All files in directory:');
      for (var f in allFiles) {
        print(' - ${f.path}');
      }

      // filtrira samo csv fajlove
      // Filter CSV files
      final csvFiles = allFiles
          .where((file) => file.path.endsWith('.csv'))
          .toList();

      print('Found ${csvFiles.length} CSV files.');

      if (csvFiles.isNotEmpty) {
        // koristimo prvi csv koji nadjemo
        final file = csvFiles.first;
        final stat = await file.stat(); // uzimamo info o fajlu

        print('Using file: ${file.path}');
        print('Last modified: ${stat.modified}');

        setState(() {
          _fileName = file.uri.pathSegments.last;
          _filePath = file.path;
          _uploadDate = stat.modified;
          _statusMessage = ' File Found In Local Storage';
        });
      } else {
        setState(() {
          _statusMessage = 'No CSV File Found In Local Storage';
        });
      }
    } catch (e) {
      print('Error while loading files: $e');
      setState(() {
        _statusMessage = 'Error loading local files: $e';
      });
    }
  }

  // brisanje csv fajla iz memorije uredjaja i cuvanje u internu memoriju
  // -> bira csv fajl i cuva ga lokalno
  Future<void> _pickAndSaveFile() async {
    setState(() {
      _statusMessage = null;
    });
    try {
      // file picker za ucitavanje csv fajla
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        final fileBytes = file.bytes;
        final fileName = file.name;

        final directory = await getApplicationDocumentsDirectory();
        final localFile = File('${directory.path}/$fileName');

        // snimanje fajla lokalno
        if (fileBytes != null) {
          await localFile.writeAsBytes(fileBytes);
        } else if (file.path != null) {
          final pickedFile = File(file.path!);
          await pickedFile.copy(localFile.path);
        } else {
          throw Exception('Could not read file bytes or path');
        }

        final fileStat = await localFile.stat();

        setState(() {
          _fileName = fileName;
          _filePath = localFile.path;
          _uploadDate = fileStat.modified;
          _statusMessage = 'File Saved Successfully To Local Storage.';
        });

        print('Saved File : ${localFile.path}');
      } else {
        setState(() {
          _statusMessage = 'File picking cancelled.';
        });
      }
    } catch (e) {
      print('Error during file pick/save: $e');
      setState(() {
        _statusMessage = 'Error: $e';
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.file_copy_outlined, color: Colors.white),
            SizedBox(width: 8),
            Text('Data'),
          ],
        ),
        backgroundColor: const Color(0xFFEF474B),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 4,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // dugme za biranje i cuvanje fajla
              ElevatedButton.icon(
                onPressed: _pickAndSaveFile,
                icon: const Icon(Icons.upload_file, size: 20),
                label: const Text(
                  'Pick CSV File',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  //backgroundColor: Colors.green,
                  backgroundColor: const Color(0xFFEF474B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(180, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      24,
                    ),
                  ),
                  elevation: 5,
                ),
              ),
              const SizedBox(height: 40),
              // prikazivanje statusne poruke ako postoji
              if (_statusMessage != null) ...[
                Container(
                  decoration: BoxDecoration(
                    color: _statusMessage!.startsWith('Error')
                        ? Colors.red.shade100
                        : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 20,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _statusMessage!.startsWith('Error')
                            ? Icons.error_outline
                            : Icons.check_circle_outline,
                        color: _statusMessage!.startsWith('Error')
                            ? Colors.red
                            : Colors.blue,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            fontSize: 15,
                            color: _statusMessage!.startsWith('Error')
                                ? Colors.red.shade800
                                : Colors.blue.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 30),
              // ako fajl postoji prikazujemo info o njemu
              if (_fileName != null) ...[
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  shadowColor: Colors.green.withOpacity(0.4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(
                          Icons.description_outlined,
                          'File Name',
                          _fileName!,
                        ),
                        const SizedBox(height: 12),
                        if (_uploadDate != null)
                          _infoRow(
                            Icons.calendar_today_outlined,
                            'Uploaded Date',
                            _formatDateTime(_uploadDate!),
                          ),
                        if (_filePath != null) ...[
                          const SizedBox(height: 12),
                          _infoRow(
                            Icons.folder_open,
                            'File Location',
                            _filePath!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFEF474B), size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label\n',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
