import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class RegulationsPage extends StatefulWidget {
  final String role;

  const RegulationsPage({super.key, required this.role});

  @override
  State<RegulationsPage> createState() => _RegulationsPageState();
}

class _RegulationsPageState extends State<RegulationsPage> {
  final storage = FirebaseStorage.instanceFor(
    bucket: 'gs://fir-test-3ef47.firebasestorage.app',
  );
  final CollectionReference _pdfCollection =
      FirebaseFirestore.instance.collection('regulations');

  Future<void> _addPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowCompression: false,
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      debugPrint("Plik wybrany: $file");
      final fileName = result.files.single.name;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Dialog(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("Dodaje plik ..."),
                ],
              ),
            ),
          );
        },
      );

      try {
        final storageRef = storage.ref().child('regulations/$fileName');
        await storageRef.putFile(file);

        final fileUrl = await storageRef.getDownloadURL();

        await _pdfCollection.add({'name': fileName, 'url': fileUrl});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plik dodany pomyślnie.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd podczas dodawania pliku: $e')),
        );
      } finally {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  Future<void> _deletePdf(String docId, String fileName) async {
    try {
      final storageRef = storage.ref().child('regulations/$fileName');
      await storageRef.delete();

      await _pdfCollection.doc(docId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plik usunięty pomyślnie.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd podczas usuwania pliku: $e')),
      );
    }
  }

  Future<bool> _checkFileExists(String fileName) async {
    try {
      final storageRef = storage.ref().child('regulations/$fileName');
      await storageRef.getDownloadURL();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _syncWithStorage() async {
    final querySnapshot = await _pdfCollection.get();
    for (var doc in querySnapshot.docs) {
      final fileName = doc['name'];
      final fileExists = await _checkFileExists(fileName);
      if (!fileExists) {
        await _pdfCollection.doc(doc.id).delete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isManager = widget.role == 'manager';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Regulamin'),
        actions: isManager
            ? [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addPdf,
                ),
              ]
            : null,
      ),
      body: FutureBuilder(
        future: _syncWithStorage(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _pdfCollection.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Brak plików.'));
              }

              final files = snapshot.data!.docs;

              return ListView.builder(
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final file = files[index];
                  final fileName = file['name'];
                  final fileUrl = file['url'];
                  final docId = file.id;

                  return ListTile(
                    leading: const Icon(Icons.picture_as_pdf),
                    title: Text(fileName),
                    trailing: isManager
                        ? IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deletePdf(docId, fileName),
                          )
                        : null,
                    onTap: () async {
                      if (await canLaunchUrl(Uri.parse(fileUrl))) {
                        await launchUrl(Uri.parse(fileUrl));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Nie można otworzyć pliku.'),
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
