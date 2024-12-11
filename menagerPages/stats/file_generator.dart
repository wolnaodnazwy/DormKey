import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/widgets.dart' as pw;

Future<String> _getUniqueFileName(
    String directory, String baseName, String extension) async {
  int counter = 1;
  String fileName = '$baseName.$extension';
  String fullPath = '$directory/$fileName';

  while (await File(fullPath).exists()) {
    fileName = '$baseName($counter).$extension';
    fullPath = '$directory/$fileName';
    counter++;
  }

  return fullPath;
}

Future<void> generateCSV({
  required List<List<String>> data,
  required String fileName,
  required BuildContext context,
}) async {
  final csv = const ListToCsvConverter().convert(data);
  final directory = await FilePicker.platform.getDirectoryPath();
  if (directory != null) {
    final uniqueFilePath = await _getUniqueFileName(directory, fileName, 'csv');

    final file = File(uniqueFilePath);
    await file.writeAsString(csv);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Plik CSV zapisany: $uniqueFilePath")),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Nie wybrano folderu")),
    );
  }
}

Future<void> generatePDF({
  required List<List<String>> data,
  required String fileName,
  required BuildContext context,
}) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "Raport",
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 20),
          ...data.map(
            (row) => pw.Text(
              row.join(" - "),
              style: const pw.TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    ),
  );

  final directory = await FilePicker.platform.getDirectoryPath();

  if (directory != null) {
    final uniqueFilePath = await _getUniqueFileName(directory, fileName, 'pdf');

    final file = File(uniqueFilePath);
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Plik PDF zapisany: $uniqueFilePath")),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Nie wybrano folderu")),
    );
  }
}