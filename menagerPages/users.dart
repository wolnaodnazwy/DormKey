import 'package:firebase_test/widgets/user_detail.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery =
                      value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Wyszukaj użytkownika",
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_statuses')
            .orderBy('displayName')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Brak użytkowników"),
            );
          }

          final users = snapshot.data!.docs.where((doc) {
            final user = doc.data() as Map<String, dynamic>;
            final role = user['role'] ?? "";
            final displayName =
                (user['displayName'] ?? "").toString().toLowerCase();
            return role != "manager" && displayName.contains(_searchQuery);
          }).toList();

          if (users.isEmpty) {
            return const Center(
              child: Text("Brak użytkowników do wyświetlenia"),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: users.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id;
              final displayName = user['displayName'] ?? "Nieznane";
              final status = user['status'] ?? "inactive";

              return Card(
                elevation: 2,
                color: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    displayName,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == "active"
                          //? Theme.of(context).colorScheme.primaryContainer
                          ? const Color(0xFFB6DDB8)
                          // : Theme.of(context).colorScheme.errorContainer,
                          : const Color(0xFFFFD6DA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      status == "active" ? "Aktywny" : "Nieaktywny",
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: status == "active"
                                // ? Theme.of(context).colorScheme.onPrimaryContainer
                                ? const Color(0xFF1F421F)
                                // : Theme.of(context).colorScheme.onErrorContainer,
                                : const Color(0xFF880F06),
                          ),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => UserDetailsPage(userId: userId),
                    ));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
