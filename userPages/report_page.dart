import 'package:firebase_test/main.dart';
import 'package:firebase_test/services/image_picker_handler.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'dart:io';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String? selectedRoom;
  String? selectedCategory;
  TextEditingController descriptionController = TextEditingController();
  bool isAnonymous = false;
  final List<File> images = [];
  final GlobalKey<ImagePickerHandlerState> _imagePickerKey =
      GlobalKey<ImagePickerHandlerState>();

  Future<File> convertToJpg(File pngImage) async {
    final bytes = await pngImage.readAsBytes();
    final decodedImage = img.decodeImage(bytes)!;
    final jpgBytes = img.encodeJpg(decodedImage);
    final jpgFile = File(pngImage.path.replaceAll('.png', '.jpg'));
    await jpgFile.writeAsBytes(jpgBytes);
    return jpgFile;
  }

  Future<void> _showPicker(
    BuildContext context,
    String collectionName,
  ) async {
    await showModalBottomSheet<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance.collection(collectionName).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final sortedDocs = snapshot.data!.docs
              ..sort((a, b) {
                final numA =
                    int.tryParse(a.id.replaceAll(RegExp(r'\D'), '')) ?? 0;
                final numB =
                    int.tryParse(b.id.replaceAll(RegExp(r'\D'), '')) ?? 0;
                return numA.compareTo(numB);
              });

            final itemCount = snapshot.data!.docs.length;

            final initialChildSize = (itemCount * 0.1).clamp(0.2, 0.5);

            return DraggableScrollableSheet(
              initialChildSize: initialChildSize,
              minChildSize: 0.2,
              maxChildSize: 0.75,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: sortedDocs.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final doc = sortedDocs[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          setState(() {
                            collectionName == "rooms"
                                ? selectedRoom = doc['name']
                                : selectedCategory = doc['name'];
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          child: Text(
                            doc['name'],
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPickerField(
                  context: context,
                  label: "Pomieszczenie",
                  hintText: "Gdzie wystąpiła usterka?",
                  selectedValue: selectedRoom,
                  icon: Icons.home_work,
                  onTap: () => _showPicker(context, 'rooms'),
                ),
                const SizedBox(height: 16),
                _buildPickerField(
                  context: context,
                  label: "Kategoria",
                  hintText: "Jaki to rodzaj usterki?",
                  selectedValue: selectedCategory,
                  icon: Icons.category,
                  onTap: () => _showPicker(context, 'defect_category'),
                ),
                const SizedBox(height: 16),
                Stack(
                  children: [
                    Container(
                      decoration: context.containerDecoration,
                      child: TextField(
                        controller: descriptionController,
                        maxLines: 7,
                        decoration: InputDecoration(
                          alignLabelWithHint: true,
                          labelText: "Opis",
                          labelStyle: Theme.of(context).textTheme.bodyLarge,
                          floatingLabelStyle: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary),
                          hintText: "Wprowadź tekst",
                          hintStyle: Theme.of(context).textTheme.bodyMedium,
                          contentPadding: const EdgeInsets.only(
                            top: 16.0,
                            left: 16.0,
                            right: 36.0,
                            bottom: 16.0,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        onChanged: (text) {
                          setState(() {});
                        },
                      ),
                    ),
                    if (descriptionController.text.isNotEmpty)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            descriptionController.clear();
                            setState(() {});
                          },
                          child: Icon(
                            Icons.clear,
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 16),
                  child: Text(
                    "Opisz dokładnie na czym polega problem",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Switch(
                      value: isAnonymous,
                      onChanged: (value) {
                        setState(() {
                          isAnonymous = value;
                        });
                      },
                    ),
                    const SizedBox(width: 10,),
                    Text(
                      "Anonimowe",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                ImagePickerHandler(
                  key: _imagePickerKey,
                  onImagesSelected: (selectedImages) {
                    setState(() {
                      images.clear();
                      images.addAll(selectedImages);
                    });
                  },
                ),
                const SizedBox(
                  height: 6,
                ),
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.45,
                    child: ElevatedButton(
                      onPressed: _submitReport,
                      child: const Text("Zgłoś"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickerField({
    required BuildContext context,
    required String label,
    required String hintText,
    required String? selectedValue,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          floatingLabelStyle: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: Theme.of(context).colorScheme.secondary),
          suffixIcon: const Icon(Icons.arrow_drop_down),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                selectedValue ?? hintText,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: selectedValue == null
                          ? Theme.of(context).colorScheme.outline
                          : Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<String>> _uploadImages(String reportId) async {
    List<String> imageUrls = [];

    for (var image in images) {
      try {
        String fileName = '${DateTime.now().millisecondsSinceEpoch}';

        final storage = FirebaseStorage.instanceFor(
          bucket: 'gs://fir-test-3ef47.firebasestorage.app',
        );
        final storageRef = storage.ref().child('reports/$reportId/$fileName');

        await storageRef.putFile(File(image.path));

        final downloadUrl = await storageRef.getDownloadURL();
        imageUrls.add(downloadUrl);

        debugPrint("Uploaded: $downloadUrl");
      } catch (e) {
        debugPrint("Error uploading image: $e");
      }
    }
    return imageUrls;
  }

  Future<void> _submitReport() async {
    if (selectedRoom == null ||
        selectedCategory == null ||
        descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Uzupełnij wszystkie pola.")));
      return;
    }

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
                Text("Dodaje zgłoszenie..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = isAnonymous ? null : user?.uid;

      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 1)
          .subtract(const Duration(days: 1));

      final querySnapshot = await FirebaseFirestore.instance
          .collection('reports')
          .where('timestamp', isGreaterThanOrEqualTo: firstDayOfMonth)
          .where('timestamp', isLessThanOrEqualTo: lastDayOfMonth)
          .get();

      final reportCount = querySnapshot.docs.length + 1;
      final reportNumber = reportCount.toString().padLeft(3, '0');
      final reportId = "${now.month}-${now.year}-$reportNumber";

      List<String> imageUrls = await _uploadImages(reportId);

      final statusReference = FirebaseFirestore.instance
          .collection('application_status')
          .doc('status_0');

      await FirebaseFirestore.instance.collection('reports').add({
        'room': selectedRoom,
        'category': selectedCategory,
        'description': descriptionController.text,
        'images': imageUrls,
        'isAnonymous': isAnonymous,
        'timestamp': FieldValue.serverTimestamp(),
        'user': userId,
        'reportId': reportId,
        'application_status': statusReference
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usterka zgłoszona pomyślnie.")),
      );

      setState(() {
        selectedRoom = null;
        selectedCategory = null;
        descriptionController.clear();
        images.clear();
        isAnonymous = false;

        _imagePickerKey.currentState?.clearImages();
      });
    } catch (e) {
      Navigator.pop(context);
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Wystąpił błąd: $e")),
      );
    }
  }
}
