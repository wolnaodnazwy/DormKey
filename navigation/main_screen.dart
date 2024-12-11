import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_test/navigation/navigation_helper.dart';
import 'package:firebase_test/navigation/user_role_provider.dart';
import 'package:firebase_test/sign_in_up/user_detail_form.dart';
import 'package:firebase_test/userPages/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream(String uid) {
    return FirebaseFirestore.instance.collection('user_statuses').doc(uid).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (authSnapshot.hasData) {
          final user = authSnapshot.data;

          if (user != null) {
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _userStream(user.uid),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return UserDetailsForm(uid: user.uid);
                }

                final userData = userSnapshot.data!.data();
                if (userData == null ||
                    !userData.containsKey('dormitory_number') ||
                    !userData.containsKey('room_number') ||
                    !userData.containsKey('province')) {
                  return UserDetailsForm(uid: user.uid);
                }

                final role = userData['role'] ?? 'user';
                final userRoleProvider =
                    Provider.of<UserRoleProvider>(context, listen: false);
                userRoleProvider.setRole(role);

                return HomePage(role: role);
              },
            );
          }
        }
        return const WelcomeScreen();
      },
    );
  }
}