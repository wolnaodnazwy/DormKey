import 'package:firebase_test/navigation/main_screen.dart';
import 'package:firebase_test/sign_in_up/google_sign_in_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_validators.dart';
import 'dart:io' show Platform;

class SignUpPage extends StatefulWidget {
  final VoidCallback onTapClickListener;

  const SignUpPage({super.key, required this.onTapClickListener});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isSigning = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void setLoading(bool loading) {
    setState(() {
      _isSigning = loading;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double iconSize = Platform.isIOS ? 44.0 : 40.0;

    return BlocListener<GoogleSignInCubit, GoogleSignInState>(
      listener: (context, state) {
        if (state is GoogleSignInSuccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } else if (state is GoogleSignInFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Google Sign-In failed: ${state.error}")),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Zarejestruj się"),
        ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('lib/assets/background.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.white.withOpacity(0.4),
                    BlendMode.lighten,
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: "Imię i nazwisko",
                          labelStyle: Theme.of(context).textTheme.labelLarge,
                          floatingLabelStyle:
                              TextStyle(color: Theme.of(context).primaryColor),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: validateName,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: "Adres e-mail",
                          labelStyle: Theme.of(context).textTheme.labelLarge,
                          floatingLabelStyle:
                              TextStyle(color: Theme.of(context).primaryColor),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: validateEmail,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: "Hasło",
                          labelStyle: Theme.of(context).textTheme.labelLarge,
                          floatingLabelStyle:
                              TextStyle(color: Theme.of(context).primaryColor),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        obscureText: true,
                        validator: validatePassword,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: 15),
                      Align(
                        alignment: Alignment.center,
                        child: FractionallySizedBox(
                          widthFactor: 0.5,
                          child: ElevatedButton(
                            onPressed: _isSigning
                                ? null
                                : () => signUpUser(
                                      context: context,
                                      formKey: _formKey,
                                      emailController: _emailController,
                                      passwordController: _passwordController,
                                      nameController: _nameController,
                                      setLoading: setLoading,
                                    ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isSigning
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                  : Theme.of(context).colorScheme.secondary,
                            ),
                            child: const Text("Zarejestruj"),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _isSigning
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Proszę poczekać..."),
                                SizedBox(width: 10),
                                CircularProgressIndicator(),
                              ],
                            )
                          : Container(),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        children: [
                          const Expanded(child: Divider(thickness: 1.5)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              "Lub",
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          const Expanded(child: Divider(thickness: 1.5)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.center,
                        child: ElevatedButton(
                          onPressed: () {
                            final provider =
                                BlocProvider.of<GoogleSignInCubit>(context);
                            provider.signInWithGoogle();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
                          ),
                          child: Image.asset(
                            'lib/assets/google_icon.png',
                            width: iconSize,
                            height: iconSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Future _signInUser() async {
//   setState(() {
//     _isSigning = true;
//   });
//   try {
//     await FirebaseAuth.instance
//         .signInWithEmailAndPassword(
//       email: _emailController.text,
//       password: _passwordController.text,
//     )
//         .then((value) {
//       setState(() {
//         _isSigning = false;
//       });
//     });
//   } catch (e) {
//     print("some error $e");
//   }
// }
}
