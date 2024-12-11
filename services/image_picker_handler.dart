import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_test/main.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerHandler extends StatefulWidget {
  final Function(List<File>) onImagesSelected;

  const ImagePickerHandler({
    super.key,
    required this.onImagesSelected,
  });

  @override
  State<ImagePickerHandler> createState() => ImagePickerHandlerState();
}

class ImagePickerHandlerState extends State<ImagePickerHandler> {
  final ImagePicker _picker = ImagePicker();
  final List<File> _images = [];
  final ScrollController _scrollController = ScrollController();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile =
          await _picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _images.add(File(pickedFile.path));
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
        widget.onImagesSelected(_images);
      } 
    } catch (e) {
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Błąd podczas obsługi zdjęcia: $e")),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          decoration: context.containerDecoration,
          child: SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Zrób zdjęcie'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Wybierz obraz z galerii'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
    widget.onImagesSelected(_images);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: _scrollController,
                child: Row(
                  children: [
                    ..._images.asMap().entries.map(
                     (entry) {
                        final index = entry.key;
                        final image = entry.value;
                        return Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Image.file(
                                File(image.path),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.all(8.0),
                      child: DottedBorder(
                        child: SizedBox(
                          width: 75,
                          height: 75,
                          child: IconButton(
                            icon: const Icon(
                              Icons.add_a_photo,
                            ),
                            onPressed: _showImageSourceDialog,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void clearImages() {
    setState(() {
      _images.clear();
    });
    widget.onImagesSelected(_images);
  }
}
