import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_test/sign_in_up/sync_with_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

@immutable
abstract class GoogleSignInState {}

class GoogleSignInInitial extends GoogleSignInState {}

class GoogleSignInSuccess extends GoogleSignInState {}

class GoogleSignInFailure extends GoogleSignInState {
  final String error;

  GoogleSignInFailure(this.error);
}

class GoogleSignInCubit extends Cubit<GoogleSignInState> {
  GoogleSignInCubit() : super(GoogleSignInInitial());

  final googleSignIn = GoogleSignIn();

  GoogleSignInAccount? _user;

  GoogleSignInAccount get user => _user!;

  Future signInWithGoogle() async {
    try {
      await googleSignIn.signOut();

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      _user = googleUser;

      final googleAuthentication = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
          idToken: googleAuthentication.idToken,
          accessToken: googleAuthentication.accessToken);

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      await syncUserToFirestore(userCredential.user!);

      emit(GoogleSignInSuccess());
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
    }
  }
}
