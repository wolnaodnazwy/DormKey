import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_test/main.dart';
import 'package:image_picker/image_picker.dart';

class ResidentialCardPage extends StatelessWidget {
  const ResidentialCardPage({super.key});

  Stream<Map<String, dynamic>> fetchUserDetails(String uid) {
    final userDoc =
        FirebaseFirestore.instance.collection('user_statuses').doc(uid);

    return userDoc.snapshots().map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data() ?? {};
      } else {
        return {};
      }
    });
  }

  final bucket = 'gs://fir-test-3ef47.firebasestorage.app';

  Future<void> _updateProfilePicture(String uid, BuildContext context) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final storage = FirebaseStorage.instanceFor(
          bucket: bucket,
        );
        final storageRef = storage.ref().child('profile_pictures/$uid.jpg');
        final uploadTask = storageRef.putFile(File(pickedFile.path));

        final snapshot = await uploadTask.whenComplete(() {});
        final photoURL = await snapshot.ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('user_statuses')
            .doc(uid)
            .update({'photoURL': photoURL});

        final user = FirebaseAuth.instance.currentUser;
        await user?.updatePhotoURL(photoURL);

        await user?.reload();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Błąd podczas przesyłania zdjęcia: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? "User Name";
    final email = user?.email ?? "Email Not Available";

    return StreamBuilder<Map<String, dynamic>>(
      stream: fetchUserDetails(user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Błąd pobierania danych użytkownika."));
        }
        final userDetails = snapshot.data ?? {};
        final isActive = (userDetails['status'] ?? 'inactive') == 'active';
        final dormitoryNumber =
            userDetails['dormitory_number'] ?? 'Brak danych';
        final roomNumber = userDetails['room_number'] ?? 'Brak danych';
        final role = userDetails['role'] ?? 'Brak danych';
        final province = userDetails['province'] ?? 'Brak danych';
        final photoURL = userDetails['photoURL'] ?? user.photoURL;

        return Scaffold(
          body: Center(
            child: Column(
              children: [
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.all(16),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: context.containerDecoration,
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFFB6DDB8)
                                : const Color(0xFFFFD6DA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isActive ? "AKTYWNA" : "NIEAKTYWNA",
                            style: TextStyle(
                              color: isActive
                                  ? const Color(0xFF1F421F)
                                  : const Color(0xFF880F06),
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.topCenter,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 80,
                              backgroundImage:
                                  photoURL != null && photoURL!.isNotEmpty
                                      ? NetworkImage(photoURL)
                                      : const AssetImage(
                                              "lib/assets/default_avatar.png")
                                          as ImageProvider,
                            ),
                            GestureDetector(
                              onTap: () =>
                                  _updateProfilePicture(user.uid, context),
                              child: Container(
                                height: 30,
                                width: 30,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[700],
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  child: Divider(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: context.containerDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Szczegóły użytkownika",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(height: 14),
                      _buildDetailRow(
                          "Numer akademika", dormitoryNumber, context),
                      const SizedBox(height: 8),
                      _buildDetailRow("Numer pokoju", roomNumber, context),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                          "Rola",
                          role == "manager"
                              ? "Kierownik"
                              : role == "student_union"
                                  ? "Samorząd Akademicki"
                                  : "Użytkownik",
                          context),
                      const SizedBox(height: 8),
                      _buildDetailRow("Województwo", province, context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ],
    );
  }
}
