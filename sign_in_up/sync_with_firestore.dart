import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> syncUserToFirestore(User user) async {
  await user.reload();
  final refreshedUser = FirebaseAuth.instance.currentUser;
  if (refreshedUser == null) {
    throw Exception("User not found after reload.");
  }
  final userDoc =
      FirebaseFirestore.instance.collection('user_statuses').doc(user.uid);
  final userSnapshot = await userDoc.get();
  if (!userSnapshot.exists) {
    await userDoc.set({
      'status': 'inactive',
      'role': 'user',
      'displayName': refreshedUser.displayName ?? 'Unknown',
      'email': refreshedUser.email,
      'photoURL': refreshedUser.photoURL ?? '',
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }
}
