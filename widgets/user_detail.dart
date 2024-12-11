import 'package:firebase_test/main.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetailsPage extends StatelessWidget {
  final String userId;

  const UserDetailsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Szczegóły użytkownika"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('user_statuses')
            .doc(userId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text("Nie znaleziono użytkownika"),
            );
          }

          final user = snapshot.data!.data() as Map<String, dynamic>;
          final displayName = user['displayName'] ?? "Nieznane";
          final email = user['email'] ?? "Nieznane";
          final role = user['role'] ?? "user";
          final status = user['status'] ?? "inactive";
          final photoUrl = user['photoURL'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: context.containerDecoration.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (photoUrl != null && photoUrl.isNotEmpty)
                          Center(
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: NetworkImage(photoUrl),
                              onBackgroundImageError: (_, __) =>
                                  const AssetImage(
                                          "lib/assets/default_avatar.png")
                                      as ImageProvider,
                            ),
                          )
                        else
                          const Center(
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: AssetImage(
                                  "lib/assets/default_avatar.png"),
                            ),
                          ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                            context, "Imię i nazwisko", displayName),
                        const SizedBox(height: 8),
                        _buildDetailRow(context, "Email", email),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                            context,
                            "Rola",
                            role == "manager"
                                ? "Kierownik"
                                : role == "student_union"
                                    ? "Samorząd Akademicki"
                                    : "Użytkownik"),
                        const SizedBox(height: 8),
                        _buildDetailRow(context, "Status",
                            status == "inactive" ? "Nieaktywna" : "Aktywna"),
                      ]),
                ),
                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  child: Divider(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      final newStatus =
                          status == "active" ? "inactive" : "active";
                      await FirebaseFirestore.instance
                          .collection('user_statuses')
                          .doc(userId)
                          .update({'status': newStatus});
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: status == "active"
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                    child: Text(
                      status == "active"
                          ? "Ustaw jako nieaktywny"
                          : "Ustaw jako aktywny",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      final newRole =
                          role == "student_union" ? "user" : "student_union";
                      await FirebaseFirestore.instance
                          .collection('user_statuses')
                          .doc(userId)
                          .update({'role': newRole});
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: role == "student_union"
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.primary,
                    ),
                    child: Text(
                      role == "student_union"
                          ? "Usuń rolę Samorząd Akademicki"
                          : "Przyznaj rolę Samorząd Akademicki",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
