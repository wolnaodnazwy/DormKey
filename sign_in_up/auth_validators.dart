import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_test/sign_in_up/sync_with_firestore.dart';
import 'package:flutter/material.dart';
import '../navigation/main_screen.dart';

String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'E-mail jest wymagany';
  }
  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
    return 'Podaj prawidłowy adres e-mail';
  }
  return null;
}

String? validateName(String? value) {
  if (value == null || value.isEmpty) {
    return 'Imię i nazwisko są wymagane';
  }
  if (!value.contains(' ')) {
    return 'Podaj pełne imię i nazwisko';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Hasło jest wymagane';
  }
  if (value.length < 6) {
    return 'Hasło musi zawierać co najmniej 6 znaków';
  }
  return null;
}

Future<void> signUpUser({
  required BuildContext context,
  required GlobalKey<FormState> formKey,
  required TextEditingController emailController,
  required TextEditingController passwordController,
  required TextEditingController nameController,
  required ValueSetter<bool> setLoading,
}) async {
  if (!formKey.currentState!.validate()) return;
  setLoading(true);
  try {
    UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: emailController.text,
      password: passwordController.text,
    );
    String displayName = nameController.text.trim();
    await userCredential.user?.updateDisplayName(displayName);
    await userCredential.user?.reload();
    await syncUserToFirestore(userCredential.user!);

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainScreen(),
        ),
      );
    }
  } on FirebaseAuthException {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Nie udało się zarejestrować. Spróbuj jeszcze raz!")),
      );
    }
  } finally {
    if (context.mounted) {
      setLoading(false);
    }
  }
}

Future<void> signInUser({
  required BuildContext context,
  required GlobalKey<FormState> formKey,
  required TextEditingController emailController,
  required TextEditingController passwordController,
  required ValueSetter<bool> setLoading,
}) async {
  if (!formKey.currentState!.validate()) return;

  setLoading(true);

  try {
    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: emailController.text,
      password: passwordController.text,
    );

    if (userCredential.user != null) {
      await syncUserToFirestore(userCredential.user!);
    }

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainScreen(),
        ),
      );
    }
  } on FirebaseAuthException {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Nie udało się zalogować! Spróbuj jeszcze raz! ")),
      );
    }
  } finally {
    if (context.mounted) {
      setLoading(false);
    }
  }
}
