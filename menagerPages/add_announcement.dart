import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_test/main.dart';
import 'package:firebase_test/services/image_picker_handler.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddAnnouncementPage extends StatefulWidget {
  const AddAnnouncementPage({super.key});

  @override
  State<AddAnnouncementPage> createState() => _AddAnnouncementPageState();
}

class _AddAnnouncementPageState extends State<AddAnnouncementPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final List<File> _selectedImages = [];
  bool _isSubmitting = false;
  final GlobalKey<ImagePickerHandlerState> _imagePickerKey =
      GlobalKey<ImagePickerHandlerState>();

  Future<List<String>> _uploadImages() async {
    List<String> uploadedUrls = [];
    for (var image in _selectedImages) {
      try {
        String fileName = '${DateTime.now().millisecondsSinceEpoch}';

        final storage = FirebaseStorage.instanceFor(
          bucket: 'gs://fir-test-3ef47.firebasestorage.app',
        );
        final storageRef = storage.ref().child('announcements/$fileName');

        await storageRef.putFile(File(image.path));

        final downloadUrl = await storageRef.getDownloadURL();
        uploadedUrls.add(downloadUrl);
      } catch (e) {
        debugPrint("Error uploading images: $e");
      }
    }
    return uploadedUrls;
  }

  Future<void> _submitAnnouncement() async {
    final user = FirebaseAuth.instance.currentUser;

    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Proszę wypełnić wszystkie pola")),
      );
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
                Text("Dodaje ogłoszenie..."),
              ],
            ),
          ),
        );
      },
    );

    setState(() {
      _isSubmitting = true;
    });

    try {
      final imageUrls = await _uploadImages();

      await FirebaseFirestore.instance.collection('announcements').add({
        'authorName': user?.displayName ?? 'Nieznany autor',
        'title': _titleController.text,
        'content': _contentController.text,
        'images': imageUrls,
        'date': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ogłoszenie zostało dodane")),
      );

      _titleController.clear();
      _contentController.clear();
      setState(() {
        _selectedImages.clear();
      });
      _imagePickerKey.currentState?.clearImages();
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Błąd podczas dodawania ogłoszenia: $e")),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
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
                Container(
                  decoration: context.containerDecoration,
                  child: TextField(
                    controller: _titleController,
                    maxLines: 1,
                    decoration: InputDecoration(
                      labelText: "Tytuł",
                      hintText: "Wpisz tytuł ogłoszenia",
                      labelStyle: Theme.of(context).textTheme.bodyLarge,
                      hintStyle: Theme.of(context).textTheme.bodyMedium,
                      floatingLabelStyle: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                              color: Theme.of(context).colorScheme.secondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Stack(
                  children: [
                    Container(
                      decoration: context.containerDecoration,
                      child: TextField(
                        controller: _contentController,
                        maxLines: 10,
                        decoration: InputDecoration(
                          labelText: "Treść",
                          hintText: "Wpisz treść ogłoszenia",
                          alignLabelWithHint: true,
                          labelStyle: Theme.of(context).textTheme.bodyLarge,
                          hintStyle: Theme.of(context).textTheme.bodyMedium,
                          floatingLabelStyle: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary),
                          contentPadding: const EdgeInsets.only(
                            top: 16.0,
                            left: 16.0,
                            right: 36.0,
                            bottom: 16.0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onChanged: (text) {
                          setState(() {});
                        },
                      ),
                    ),
                    if (_contentController.text.isNotEmpty)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            _contentController.clear();
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
                const SizedBox(height: 16),
                ImagePickerHandler(
                  key: _imagePickerKey,
                  onImagesSelected: (selectedImages) {
                    setState(() {
                      _selectedImages.clear();
                      _selectedImages.addAll(selectedImages);
                    });
                  },
                ),
                const SizedBox(height: 16),
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitAnnouncement,
                      child: _isSubmitting
                          ? const CircularProgressIndicator()
                          : const Text("Dodaj"),
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
}
